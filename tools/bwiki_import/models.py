from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class SourceSpec:
    source_key: str
    title: str
    level: str
    local_filenames: tuple[str, ...]


@dataclass(frozen=True)
class ValidatedResponse:
    spec: SourceSpec
    source_path: Path
    raw_bytes: bytes
    content: str
    canonical_title: str
    page_id: int
    revision_id: int
    revised_at_utc: str
    content_bytes: int
    api_sha1: str
    content_sha1: str
    content_sha256: str
    response_sha256: str
    content_model: str
    warnings: Any

    def lock_record(self) -> dict[str, Any]:
        return {
            "source_key": self.spec.source_key,
            "level": self.spec.level,
            "source_filename": self.source_path.name,
            "requested_title": self.spec.title,
            "canonical_title": self.canonical_title,
            "page_id": self.page_id,
            "revision_id": self.revision_id,
            "revised_at_utc": self.revised_at_utc,
            "content_bytes": self.content_bytes,
            "api_sha1": self.api_sha1,
            "content_sha1": self.content_sha1,
            "content_sha256": self.content_sha256,
            "response_sha256": self.response_sha256,
            "content_model": self.content_model,
            "warnings": self.warnings,
            "response_file": f"responses/{self.spec.source_key}.json",
            "content_file": f"content/{self.spec.source_key}.lua",
        }


@dataclass(frozen=True)
class FrozenSnapshot:
    snapshot_id: str
    path: Path
    lock_path: Path
    source_keys: tuple[str, ...]
    reused_existing: bool
