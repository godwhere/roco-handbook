from __future__ import annotations

from collections import Counter, defaultdict
import json
from pathlib import Path
import re
from typing import Any

from .adapters.common import require_mapping, require_string, to_plain
from .adapters.core import CoreInspection, inspect_core
from .adapters.evolution import EvolutionInspection, inspect_evolution
from .adapters.handbook import HandbookInspection, inspect_handbook
from .adapters.index import IndexInspection, inspect_index
from .adapters.learnsets import LearnsetInspection, inspect_learnsets
from .adapters.skills import SkillInspection, inspect_skills
from .errors import AdapterError, LuaSyntaxError, ReportWriteError
from .lua_parser import LuaParseResult, parse_lua_table
from .rendered_index import RenderedIndexInspection, inspect_rendered_pet_index


_DATA_MODULES = (
    "core",
    "index",
    "handbook",
    "evolution",
    "skill_catalog",
    "learnsets",
    "learnset_catalog",
)
_REVIEW_MODULES = ("pet_module", "skills_module", "dex_index_module")
_REQUIRE_CALL = re.compile(r'require\("([^"]+)"\)')


def _load_lock(snapshot: Path) -> dict[str, Any]:
    lock_path = snapshot / "sources.lock.json"
    try:
        lock = json.loads(lock_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise AdapterError(f"Cannot read snapshot lock {lock_path}: {error}") from error
    if lock.get("snapshot_id") != snapshot.name:
        raise AdapterError("Snapshot directory name does not match sources.lock.json")
    return lock


def _source_by_key(lock: dict[str, Any]) -> dict[str, dict[str, Any]]:
    sources = lock.get("sources")
    if not isinstance(sources, list):
        raise AdapterError("Snapshot lock sources must be an array")
    result: dict[str, dict[str, Any]] = {}
    for source in sources:
        if not isinstance(source, dict) or not isinstance(source.get("source_key"), str):
            raise AdapterError("Snapshot lock contains an invalid source record")
        key = source["source_key"]
        if key in result:
            raise AdapterError(f"Snapshot lock repeats source {key}")
        result[key] = source
    return result


def _parse_sources(
    snapshot: Path,
    source_records: dict[str, dict[str, Any]],
) -> tuple[dict[str, LuaParseResult], dict[str, dict[str, Any]]]:
    parsed: dict[str, LuaParseResult] = {}
    stats: dict[str, dict[str, Any]] = {}
    for key in _DATA_MODULES:
        source = source_records.get(key)
        if source is None:
            raise AdapterError(f"Snapshot is missing required data module {key}")
        path = snapshot / str(source.get("content_file", ""))
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as error:
            raise AdapterError(f"Cannot read {key} content: {error}") from error
        result = parse_lua_table(text, source=path.name)
        parsed[key] = result
        stats[key] = {
            "content_bytes": len(text.encode("utf-8")),
            "token_count": result.token_count,
            "maximum_table_depth": result.max_depth,
            "top_level_table_kind": result.value.kind,
            "top_level_field_count": len(result.value.fields),
        }
    return parsed, stats


def _review_code_modules(
    snapshot: Path,
    source_records: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    reports: dict[str, Any] = {}
    for key in _REVIEW_MODULES:
        source = source_records.get(key)
        if source is None:
            reports[key] = {"present": False}
            continue
        path = snapshot / str(source["content_file"])
        text = path.read_text(encoding="utf-8")
        rejection = None
        try:
            parse_lua_table(text, source=path.name)
        except LuaSyntaxError as error:
            rejection = str(error)
        if rejection is None:
            raise AdapterError(f"Executable review module {key} was accepted as data")
        observations: dict[str, Any] = {
            "recursive_key_translation": "translateKeys" in text,
            "learnset_stage_filter": False
            if key == "skills_module" and "native_skills" in text
            else None,
        }
        if key == "dex_index_module":
            observations.update(
                {
                    "handbook_public_number_match": (
                        'pet.handbook.id:match("^handbook_(%d+)$")' in text
                    ),
                    "public_number_zero_padding": (
                        'string.format("%03d", tonumber(raw) or 0)' in text
                    ),
                    "rendered_main_form_marker": 'data-param5="' in text
                    and "main_form" in text,
                }
            )
        reports[key] = {
            "present": True,
            "parsed_as_data": False,
            "safe_parser_rejection": rejection,
            "declared_dependencies": sorted(set(_REQUIRE_CALL.findall(text))),
            "review_observations": observations,
        }
    return reports


def _reference_report(
    core: CoreInspection,
    index: IndexInspection,
    handbook: HandbookInspection,
    evolution: EvolutionInspection,
    skills: SkillInspection,
    learnsets: LearnsetInspection,
) -> dict[str, Any]:
    pet_ids = set(core.records)
    handbook_ids = set(handbook.records)
    evolution_ids = set(evolution.records)
    skill_ids = set(skills.records)
    learnset_ids = set(learnsets.records)
    return {
        "core_vs_index_ids": {
            "missing_from_index": sorted(pet_ids - index.by_id),
            "missing_from_core": sorted(index.by_id - pet_ids),
        },
        "index_pet_references_missing_from_core": sorted(
            index.referenced_pet_ids - pet_ids
        ),
        "handbook_references_missing": sorted(
            core.handbook_references - handbook_ids
        ),
        "evolution_group_references_missing": sorted(
            core.evolution_references - evolution_ids
        ),
        "evolution_members_missing_from_core": sorted(
            evolution.member_pet_ids - pet_ids
        ),
        "learnset_pet_assignments_missing_from_core": sorted(
            set(learnsets.pet_to_learnset) - pet_ids
        ),
        "core_pets_missing_learnset_assignment": sorted(
            pet_ids - set(learnsets.pet_to_learnset)
        ),
        "learnset_references_missing": sorted(
            set(learnsets.pet_to_learnset.values()) - learnset_ids
        ),
        "core_feature_skills_missing": sorted(
            core.feature_references - skill_ids
        ),
        "learnset_feature_skills_missing": sorted(
            learnsets.feature_references - skill_ids
        ),
        "learnset_skills_missing": sorted(learnsets.skill_references - skill_ids),
    }


def _feature_resolution(
    core: CoreInspection,
    learnsets: LearnsetInspection,
) -> dict[str, Any]:
    counts: Counter[str] = Counter()
    conflicts: list[dict[str, str]] = []
    for pet_id, pet in core.records.items():
        core_feature = pet.get("feature_skill")
        learnset_id = learnsets.pet_to_learnset.get(pet_id)
        learnset = learnsets.records.get(learnset_id or "")
        learnset_feature = learnset.get("feature_skill") if learnset else None
        if core_feature is None and learnset_feature is None:
            counts["missing"] += 1
        elif core_feature is None:
            counts["learnset_fallback"] += 1
        elif learnset_feature is None:
            counts["core_only"] += 1
        elif core_feature == learnset_feature:
            counts["matching"] += 1
        else:
            counts["conflict"] += 1
            conflicts.append(
                {
                    "pet_id": pet_id,
                    "core_feature_skill_id": require_string(
                        core_feature,
                        f"core.{pet_id}.feature_skill",
                    ),
                    "learnset_feature_skill_id": require_string(
                        learnset_feature,
                        f"learnset.{pet_id}.feature_skill",
                    ),
                }
            )
    return {"counts": dict(sorted(counts.items())), "conflicts": conflicts}


def _default_display_resolution(
    core: CoreInspection,
    handbook: HandbookInspection,
    overrides_path: Path | None,
) -> dict[str, Any]:
    overrides: dict[str, str] = {}
    override_evidence: dict[str, str] = {}
    if overrides_path is not None:
        document = json.loads(overrides_path.read_text(encoding="utf-8"))
        for raw in document.get("overrides", []):
            if not isinstance(raw, dict):
                raise AdapterError("Handbook display override must be an object")
            handbook_id = raw.get("handbook_id")
            pet_id = raw.get("default_pet_id")
            if not isinstance(handbook_id, str) or not isinstance(pet_id, str):
                raise AdapterError("Handbook display override IDs must be strings")
            evidence = raw.get("evidence")
            if not isinstance(evidence, str) or not evidence:
                raise AdapterError("Handbook display override requires evidence")
            if handbook_id in overrides:
                raise AdapterError(f"Duplicate handbook display override {handbook_id}")
            overrides[handbook_id] = pet_id
            override_evidence[handbook_id] = evidence

    by_handbook: dict[str, list[str]] = defaultdict(list)
    for pet_id, record in core.records.items():
        handbook_value = record.get("handbook")
        if handbook_value is None:
            continue
        handbook_id = require_string(
            require_mapping(handbook_value, f"core.{pet_id}.handbook").get("id"),
            f"core.{pet_id}.handbook.id",
        )
        by_handbook[handbook_id].append(pet_id)

    resolved: dict[str, dict[str, str]] = {}
    unresolved: dict[str, dict[str, Any]] = {}
    for handbook_id, handbook_record in handbook.records.items():
        candidates = sorted(by_handbook.get(handbook_id, []))
        override = overrides.get(handbook_id)
        if override is not None:
            if override not in candidates:
                raise AdapterError(
                    f"Display override {handbook_id} -> {override} is not a referenced form"
                )
            resolved[handbook_id] = {
                "default_pet_id": override,
                "selection_reason": "reviewed_override",
                "evidence": override_evidence[handbook_id],
            }
            continue

        entry_name = handbook_record.get("entry_name")
        exact = [
            pet_id
            for pet_id in candidates
            if core.records[pet_id].get("name") == entry_name
            and core.records[pet_id].get("form") is None
        ]
        if len(exact) == 1:
            resolved[handbook_id] = {
                "default_pet_id": exact[0],
                "selection_reason": "unique_unformed_name_match",
            }
        else:
            unresolved[handbook_id] = {
                "candidate_pet_ids": candidates,
                "exact_unformed_name_matches": exact,
                "entry_name": entry_name,
            }
    return {
        "resolved_count": len(resolved),
        "unresolved_count": len(unresolved),
        "selection_rules": [
            "Use a reviewed override when present.",
            "Otherwise require exactly one unformed creature whose name equals entry_name.",
            "Do not use show_topics or hide_entry_name as an unverified default-form rule.",
            "Never derive the default from ID order or suffixes.",
        ],
        "resolved": resolved,
        "unresolved": unresolved,
    }


def _sample_mappings(
    core: CoreInspection,
    handbook: HandbookInspection,
    skills: SkillInspection,
    learnsets: LearnsetInspection,
) -> dict[str, Any]:
    pet_ids = ("pet_000007", "pet_000538", "pet_000595")
    pets: dict[str, Any] = {}
    for pet_id in pet_ids:
        record = core.records.get(pet_id)
        if record is None:
            pets[pet_id] = {"missing": True}
            continue
        handbook_value = require_mapping(record["handbook"], f"core.{pet_id}.handbook")
        learnset_id = learnsets.pet_to_learnset.get(pet_id)
        learnset = learnsets.records.get(learnset_id or "")
        pets[pet_id] = {
            "pet_id": pet_id,
            "name": record.get("name"),
            "handbook_id": handbook_value.get("id"),
            "core_feature_skill_id": record.get("feature_skill"),
            "learnset_id": learnset_id,
            "learnset_feature_skill_id": learnset.get("feature_skill") if learnset else None,
            "stats": to_plain(record.get("stats")),
        }
    handbook_record = handbook.records.get("handbook_000004")
    skill_record = skills.records.get("skill_000003")
    return {
        "three_form_creature": {
            "pets": pets,
            "shared_handbook_id": "handbook_000004",
            "all_forms_share_handbook": all(
                item.get("handbook_id") == "handbook_000004"
                for item in pets.values()
            ),
            "distinct_pet_ids": len(set(pets)) == 3,
            "handbook_entry": None
            if handbook_record is None
            else {key: to_plain(value) for key, value in handbook_record.items()},
            "base_feature": None
            if skill_record is None
            else {
                "skill_id": "skill_000003",
                "name": skill_record.get("name"),
                "category": skill_record.get("category"),
            },
            "base_core_and_learnset_feature_match": (
                pets.get("pet_000007", {}).get("core_feature_skill_id")
                == "skill_000003"
                and pets.get("pet_000007", {}).get("learnset_feature_skill_id")
                == "skill_000003"
            ),
        }
    }


def build_inspection_report(
    snapshot: Path,
    *,
    display_overrides_path: Path | None = None,
    rendered_index_response_path: Path | None = None,
) -> tuple[dict[str, Any], dict[str, Any]]:
    lock = _load_lock(snapshot)
    source_records = _source_by_key(lock)
    parsed, parser_stats = _parse_sources(snapshot, source_records)

    core = inspect_core(parsed["core"].value)
    index = inspect_index(parsed["index"].value)
    handbook = inspect_handbook(parsed["handbook"].value)
    evolution = inspect_evolution(parsed["evolution"].value)
    skills = inspect_skills(parsed["skill_catalog"].value)
    learnsets = inspect_learnsets(
        parsed["learnsets"].value,
        parsed["learnset_catalog"].value,
    )
    references = _reference_report(core, index, handbook, evolution, skills, learnsets)
    feature_resolution = _feature_resolution(core, learnsets)
    display_resolution = _default_display_resolution(
        core,
        handbook,
        display_overrides_path,
    )
    rendered_index: RenderedIndexInspection | None = None
    if rendered_index_response_path is not None:
        rendered_index = inspect_rendered_pet_index(rendered_index_response_path, core)
        handbook.report["display_number"] = {
            "source_field": None,
            "verified_count": len(rendered_index.display_number_by_handbook),
            "status": "verified_from_rendered_index",
            "evidence_response_sha256": rendered_index.report["response_sha256"],
            "evidence_page_revision_id": rendered_index.report["page_revision_id"],
            "rule": (
                "Preserve the displayed card value observed in the rendered upstream "
                "index; do not derive it locally from an ID suffix."
            ),
        }
    samples = _sample_mappings(core, handbook, skills, learnsets)

    blocking: list[dict[str, Any]] = []
    for label, missing in references.items():
        if isinstance(missing, list) and missing:
            blocking.append(
                {
                    "code": "unclosed_reference",
                    "context": label,
                    "count": len(missing),
                }
            )
        elif isinstance(missing, dict):
            for side, values in missing.items():
                if values:
                    blocking.append(
                        {
                            "code": "identity_set_mismatch",
                            "context": f"{label}.{side}",
                            "count": len(values),
                        }
                    )
    if feature_resolution["conflicts"]:
        blocking.append(
            {
                "code": "feature_conflict",
                "count": len(feature_resolution["conflicts"]),
            }
        )
    for module_name, module_report in {
        "core": core.report,
        "handbook": handbook.report,
        "evolution": evolution.report,
        "skill_catalog": skills.report,
        "learnset_catalog": learnsets.report,
    }.items():
        if module_report.get("unknown_fields"):
            blocking.append(
                {
                    "code": "unknown_fields",
                    "context": module_name,
                    "count": len(module_report["unknown_fields"]),
                }
            )
    if display_resolution["unresolved_count"]:
        blocking.append(
            {
                "code": "unresolved_default_forms",
                "count": display_resolution["unresolved_count"],
            }
        )
    if rendered_index is None:
        blocking.append({"code": "rendered_index_evidence_missing"})
    else:
        handbook_ids = set(handbook.records)
        number_ids = set(rendered_index.display_number_by_handbook)
        main_ids = set(rendered_index.main_pet_by_handbook)
        if handbook_ids != number_ids:
            blocking.append(
                {
                    "code": "rendered_display_number_coverage_mismatch",
                    "missing_count": len(handbook_ids - number_ids),
                    "unexpected_count": len(number_ids - handbook_ids),
                }
            )
        if handbook_ids != main_ids:
            blocking.append(
                {
                    "code": "rendered_main_form_coverage_mismatch",
                    "missing_count": len(handbook_ids - main_ids),
                    "unexpected_count": len(main_ids - handbook_ids),
                }
            )
        rendered_mismatches = [
            handbook_id
            for handbook_id, resolved in display_resolution["resolved"].items()
            if rendered_index.main_pet_by_handbook.get(handbook_id)
            != resolved["default_pet_id"]
        ]
        if rendered_mismatches:
            blocking.append(
                {
                    "code": "default_form_rendered_evidence_mismatch",
                    "count": len(rendered_mismatches),
                    "handbook_ids": rendered_mismatches,
                }
            )
    if not samples["three_form_creature"]["all_forms_share_handbook"]:
        blocking.append({"code": "sample_handbook_invariant_failed"})
    if not samples["three_form_creature"]["base_core_and_learnset_feature_match"]:
        blocking.append({"code": "sample_feature_invariant_failed"})

    warnings = [
        {
            "code": "disabled_v1_sources_not_imported",
            "sources": [
                "head_overrides",
                "skill_stone_topics",
                "topic_rewards",
            ],
        },
    ]
    if rendered_index is None:
        warnings.insert(
            0,
            {
                "code": "handbook_display_numbers_unavailable",
                "count": len(handbook.records),
                "detail": (
                    "No rendered-index evidence was provided. Handbook ID suffixes "
                    "are not used as display numbers."
                ),
            },
        )

    report = {
        "report_version": 1,
        "adapter_version": "phase1-v1",
        "dataset_id": lock.get("dataset_id"),
        "snapshot_id": lock.get("snapshot_id"),
        "status": "blocked" if blocking else "passed_with_warnings",
        "source_revisions": {
            key: {
                "revision_id": value.get("revision_id"),
                "content_sha256": value.get("content_sha256"),
                "response_sha256": value.get("response_sha256"),
            }
            for key, value in sorted(source_records.items())
        },
        "parser": parser_stats,
        "code_module_review": _review_code_modules(snapshot, source_records),
        "rendered_index_evidence": None
        if rendered_index is None
        else rendered_index.report,
        "modules": {
            "core": core.report,
            "index": index.report,
            "handbook": handbook.report,
            "evolution": evolution.report,
            "skill_catalog": skills.report,
            "learnsets": learnsets.report,
        },
        "references": references,
        "feature_resolution": feature_resolution,
        "handbook_default_display": display_resolution,
        "blocking_issues": blocking,
        "warnings": warnings,
    }
    return report, samples


def _markdown_summary(report: dict[str, Any], samples: dict[str, Any]) -> str:
    modules = report["modules"]
    sample = samples["three_form_creature"]
    lines = [
        "# Phase 1 snapshot inspection",
        "",
        f"- Snapshot: `{report['snapshot_id']}`",
        f"- Status: `{report['status']}`",
        f"- Concrete creatures: {modules['core']['record_count']}",
        f"- Handbook entries: {modules['handbook']['record_count']}",
        f"- Skills: {modules['skill_catalog']['record_count']}",
        f"- Learnsets: {modules['learnsets']['record_count']}",
        f"- Evolution groups: {modules['evolution']['record_count']}",
        (
            "- Verified handbook display numbers: "
            f"{modules['handbook']['display_number']['verified_count']}"
        ),
        (
            "- Resolved default handbook forms: "
            f"{report['handbook_default_display']['resolved_count']}"
        ),
        "",
        "## Verified invariants",
        "",
        f"- Three distinct sample IDs: {sample['distinct_pet_ids']}.",
        f"- All three sample forms share handbook_000004: {sample['all_forms_share_handbook']}.",
        (
            "- pet_000007 resolves skill_000003 in both Core and Learnset: "
            f"{sample['base_core_and_learnset_feature_match']}."
        ),
        "- Every required data module was parsed by the restricted table parser.",
        "- Executable review modules were rejected by the data parser.",
        "",
        "## Blocking issues",
        "",
    ]
    if report["blocking_issues"]:
        lines.extend(
            f"- `{item['code']}`: {item.get('context', '')} "
            f"(count={item.get('count', 1)})".rstrip()
            for item in report["blocking_issues"]
        )
    else:
        lines.append("- None.")
    lines.extend(
        [
            "",
            "## Warnings",
            "",
            *[
                f"- `{item['code']}`: {item.get('detail', item.get('sources', ''))}"
                for item in report["warnings"]
            ],
            "",
            (
                "The report preserves unknown or unresolved source semantics instead of "
                "fabricating values."
            ),
            "",
        ]
    )
    return "\n".join(lines)


def write_inspection_report(
    snapshot: Path,
    output_root: Path,
    *,
    display_overrides_path: Path | None = None,
    rendered_index_response_path: Path | None = None,
) -> Path:
    report, samples = build_inspection_report(
        snapshot,
        display_overrides_path=display_overrides_path,
        rendered_index_response_path=rendered_index_response_path,
    )
    output = output_root / str(report["snapshot_id"])
    try:
        output.mkdir(parents=True, exist_ok=True)
        (output / "structure-report.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        (output / "sample-mappings.json").write_text(
            json.dumps(samples, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        (output / "README.md").write_text(
            _markdown_summary(report, samples),
            encoding="utf-8",
        )
    except OSError as error:
        raise ReportWriteError(f"Cannot write inspection report: {error}") from error
    return output
