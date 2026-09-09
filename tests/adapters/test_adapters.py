import json
from pathlib import Path
import tempfile
import unittest

from catalog_builder.adapters.core import inspect_core
from catalog_builder.adapters.evolution import inspect_evolution
from catalog_builder.adapters.handbook import inspect_handbook
from catalog_builder.adapters.index import inspect_index
from catalog_builder.adapters.learnsets import inspect_learnsets
from catalog_builder.adapters.skills import inspect_skills
from catalog_builder.inspection import _default_display_resolution
from catalog_builder.lua_parser import parse_lua_table
from catalog_builder.rendered_index import inspect_rendered_pet_index


def table(source: str):
    return parse_lua_table(source).value


def core_fixture():
    return inspect_core(
        table(
            """
            return {
              _meta={key={n="name",t="title",h="handbook",st="show_topics"}},
              pet_000001={id="pet_000001",n="Alpha",t="Alpha Page",form="First",
                h={id="handbook_000001",st=true},feature_skill="skill_000001",
                evolution_groups={"evo_000001"}},
              pet_000002={id="pet_000002",n="Alpha",t="Alpha Variant",form="Second",
                h={id="handbook_000001",st=false},feature_skill="skill_000001",
                evolution_groups={"evo_000001"}}
            }
            """
        )
    )


class AdapterTests(unittest.TestCase):
    def test_core_expands_metadata_and_preserves_distinct_forms(self) -> None:
        result = core_fixture()
        self.assertEqual({"pet_000001", "pet_000002"}, set(result.records))
        self.assertEqual("Alpha", result.records["pet_000001"]["name"])
        self.assertEqual({"handbook_000001"}, result.handbook_references)
        self.assertEqual({"evo_000001"}, result.evolution_references)

    def test_index_preserves_every_reference(self) -> None:
        result = inspect_index(
            table(
                """
                return {
                  by_id={pet_000001=true,pet_000002=true},
                  by_name={Alpha={"pet_000001","pet_000002"}},
                  by_title={["Alpha Page"]="pet_000001",["Alpha Variant"]="pet_000002"},
                  titles={pet_000001="Alpha Page",pet_000002="Alpha Variant"}
                }
                """
            )
        )
        self.assertEqual(2, result.report["by_id_count"])
        self.assertEqual(1, result.report["duplicate_name_count"])
        self.assertEqual({"pet_000001", "pet_000002"}, result.referenced_pet_ids)

    def test_evolution_edges_follow_chain_and_lord_branch_contracts(self) -> None:
        result = inspect_evolution(
            table(
                """
                return {evo_000001={name="Alpha line",
                  chain={{id="pet_000001"},{id="pet_000002",level=10,cond="Level"}},
                  lord_branches={{id="pet_000003",cond="Review"}}}}
                """
            )
        )
        self.assertEqual(
            [
                ("chain", "pet_000001", "pet_000002", "Level"),
                ("lord_branch", "pet_000002", "pet_000003", "Review"),
            ],
            [
                (
                    edge["edge_kind"],
                    edge["from_pet_id"],
                    edge["to_pet_id"],
                    edge["condition_text"],
                )
                for edge in result.edges
            ],
        )

    def test_skills_and_learnsets_preserve_conditions_and_shared_sets(self) -> None:
        skills = inspect_skills(
            table(
                """
                return {skill_000001={name="Pulse",category="Attack",energy="Variable",
                  desc_notes={"note_001"}}}
                """
            )
        )
        learnsets = inspect_learnsets(
            table(
                "return {pet_000001='learnset_000001',pet_000002='learnset_000001'}"
            ),
            table(
                """
                return {_meta={key={fs="feature_skill",ns="native_skills",sk="skill",
                  lv="level",sg="stage",bs="blood_skills",bl="blood",ss="skill_stones"}},
                  learnset_000001={fs="skill_000001",
                    ns={{sk="skill_000001",lv=5,sg=2}},
                    bs={{sk="skill_000001",lv=7,bl="Condition"}},
                    ss={"skill_000001"}}}
                """
            ),
        )
        self.assertEqual("Variable", skills.records["skill_000001"]["energy"])
        self.assertEqual(1, learnsets.report["shared_learnset_count"])
        self.assertEqual({"2": 1}, learnsets.report["source_stage"]["observed_values"])
        self.assertEqual({"skill_000001"}, learnsets.skill_references)

    def test_default_form_requires_evidence_when_names_are_ambiguous(self) -> None:
        core = core_fixture()
        handbook = inspect_handbook(
            table('return {handbook_000001={entry_name="Alpha",title="Entry"}}')
        )
        unresolved = _default_display_resolution(core, handbook, None)
        self.assertEqual(1, unresolved["unresolved_count"])

        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "overrides.json"
            path.write_text(
                json.dumps(
                    {
                        "overrides": [
                            {
                                "handbook_id": "handbook_000001",
                                "default_pet_id": "pet_000001",
                                "evidence": "rendered-index-revision-1",
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            resolved = _default_display_resolution(core, handbook, path)
        self.assertEqual(0, resolved["unresolved_count"])
        self.assertEqual(
            "reviewed_override",
            resolved["resolved"]["handbook_000001"]["selection_reason"],
        )

    def test_rendered_index_maps_observed_number_and_main_form(self) -> None:
        core = core_fixture()
        main_marker = "\u4e3b\u5f62\u6001"
        html = (
            '<div class="dex-pet-card" data-param5="'
            + main_marker
            + '"><div class="dex-card-kicker">NO.001<span>Stage</span></div>'
            '<div class="dex-card-name"><a title="Alpha Page">Alpha</a></div></div>'
            '<div class="dex-pet-card" data-param5=""><div class="dex-card-kicker">'
            'NO.001<span>Stage</span></div><div class="dex-card-name">'
            '<a title="Alpha Variant">Alpha</a></div></div>'
        )
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "rendered.json"
            path.write_text(
                json.dumps(
                    {
                        "parse": {
                            "title": "Pet Index",
                            "pageid": 1,
                            "revid": 2,
                            "text": html,
                        }
                    }
                ),
                encoding="utf-8",
            )
            result = inspect_rendered_pet_index(path, core)
        self.assertEqual(
            {"handbook_000001": "pet_000001"},
            result.main_pet_by_handbook,
        )
        self.assertEqual(
            {"handbook_000001": "001"},
            result.display_number_by_handbook,
        )


if __name__ == "__main__":
    unittest.main()
