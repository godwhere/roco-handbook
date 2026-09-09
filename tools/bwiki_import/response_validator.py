from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
from typing import Any

from .errors import InputError, ResponseValidationError
from .models import SourceSpec, ValidatedResponse


_HEX_SHA1 = re.compile(r"^[0-9a-f]{40}$")
_BASE36_SHA1 = re.compile(r"^[0-9a-z]{1,31}$")


def _fail(path: Path, detail: str) -> ResponseValidationError:
    return ResponseValidationError(f"{path.name}: {detail}")


def _base36(number: int) -> str:
    alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"
    if number == 0:
        return "0"
    digits: list[str] = []
    while number:
        number, remainder = divmod(number, 36)
        digits.append(alphabet[remainder])
    return "".join(reversed(digits))


def _sha1_matches(api_sha1: str, content_sha1: str) -> bool:
    normalized = api_sha1.lower()
    if _HEX_SHA1.fullmatch(normalized):
        return normalized == content_sha1
    if _BASE36_SHA1.fullmatch(normalized):
        return normalized.lstrip("0") == _base36(int(content_sha1, 16)).lstrip("0")
    return False


def _title_tail(title: str) -> str:
    return title.split(":", 1)[-1]


def _as_mapping(value: Any, path: Path, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise _fail(path, f"{label} must be an object")
    return value


def validate_response(path: Path, spec: SourceSpec) -> ValidatedResponse:
    try:
        raw_bytes = path.read_bytes()
    except OSError as error:
        raise InputError(f"Cannot read {path}: {error}") from error

    try:
        document = json.loads(raw_bytes)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise _fail(path, f"response is not valid UTF-8 JSON: {error}") from error

    root = _as_mapping(document, path, "response")
    if root.get("error") is not None:
        raise _fail(path, f"MediaWiki API error: {root['error']!r}")

    query = _as_mapping(root.get("query"), path, "query")
    pages = query.get("pages")
    if not isinstance(pages, list) or len(pages) != 1:
        raise _fail(path, "query.pages must contain exactly one page")

    page = _as_mapping(pages[0], path, "query.pages[0]")
    if "missing" in page or "invalid" in page:
        raise _fail(path, "requested page is missing or invalid")

    page_id = page.get("pageid")
    if not isinstance(page_id, int) or isinstance(page_id, bool) or page_id <= 0:
        raise _fail(path, "pageid must be a positive integer")

    canonical_title = page.get("title")
    if not isinstance(canonical_title, str) or not canonical_title:
        raise _fail(path, "canonical page title is missing")
    if _title_tail(canonical_title) != _title_tail(spec.title):
        raise _fail(
            path,
            f"canonical title {canonical_title!r} does not match {spec.title!r}",
        )

    revisions = page.get("revisions")
    if not isinstance(revisions, list) or len(revisions) != 1:
        raise _fail(path, "page must contain exactly one revision")
    revision = _as_mapping(revisions[0], path, "revision")

    revision_id = revision.get("revid")
    if not isinstance(revision_id, int) or isinstance(revision_id, bool) or revision_id <= 0:
        raise _fail(path, "revision ID must be a positive integer")

    revised_at_utc = revision.get("timestamp")
    if not isinstance(revised_at_utc, str) or not revised_at_utc.endswith("Z"):
        raise _fail(path, "revision timestamp must be a UTC string")

    reported_size = revision.get("size")
    if not isinstance(reported_size, int) or isinstance(reported_size, bool) or reported_size < 0:
        raise _fail(path, "revision size must be a non-negative integer")

    slots = _as_mapping(revision.get("slots"), path, "revision.slots")
    main_slot = _as_mapping(slots.get("main"), path, "revision.slots.main")
    content = main_slot.get("content")
    if not isinstance(content, str):
        raise _fail(path, "main slot content must be a string")
    content_raw = content.encode("utf-8")
    if len(content_raw) != reported_size:
        raise _fail(
            path,
            f"content byte length {len(content_raw)} does not match revision size {reported_size}",
        )

    api_sha1 = revision.get("sha1")
    if not isinstance(api_sha1, str) or not api_sha1:
        raise _fail(path, "revision SHA-1 is missing")
    content_sha1 = hashlib.sha1(content_raw).hexdigest()
    if not _sha1_matches(api_sha1, content_sha1):
        raise _fail(path, "computed content SHA-1 does not match the API value")

    content_model = main_slot.get("contentmodel")
    if not isinstance(content_model, str) or not content_model:
        raise _fail(path, "main slot content model is missing")

    return ValidatedResponse(
        spec=spec,
        source_path=path,
        raw_bytes=raw_bytes,
        content=content,
        canonical_title=canonical_title,
        page_id=page_id,
        revision_id=revision_id,
        revised_at_utc=revised_at_utc,
        content_bytes=len(content_raw),
        api_sha1=api_sha1,
        content_sha1=content_sha1,
        content_sha256=hashlib.sha256(content_raw).hexdigest(),
        response_sha256=hashlib.sha256(raw_bytes).hexdigest(),
        content_model=content_model,
        warnings=root.get("warnings"),
    )
