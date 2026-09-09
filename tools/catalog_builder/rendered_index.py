from __future__ import annotations

from dataclasses import dataclass
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import re
from typing import Any

from .adapters.common import require_mapping, require_string
from .adapters.core import CoreInspection
from .errors import AdapterError


_NUMBER = re.compile(r"NO\.([0-9]+|\?+)")
_MAIN_FORM_MARKER = "\u4e3b\u5f62\u6001"


@dataclass(frozen=True)
class _RenderedCard:
    title: str
    display_number: str
    is_main_form: bool


@dataclass(frozen=True)
class RenderedIndexInspection:
    report: dict[str, Any]
    main_pet_by_handbook: dict[str, str]
    display_number_by_handbook: dict[str, str]


class _CardParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.cards: list[_RenderedCard] = []
        self._depth = 0
        self._card_attributes: dict[str, str] | None = None
        self._title: str | None = None
        self._kicker_depth: int | None = None
        self._name_depth: int | None = None
        self._kicker_text: list[str] = []

    def handle_starttag(
        self,
        tag: str,
        attributes: list[tuple[str, str | None]],
    ) -> None:
        attrs = {key: value or "" for key, value in attributes}
        classes = set(attrs.get("class", "").split())
        if self._card_attributes is None:
            if tag == "div" and "dex-pet-card" in classes:
                self._card_attributes = attrs
                self._depth = 1
                self._title = None
                self._kicker_depth = None
                self._name_depth = None
                self._kicker_text = []
            return

        if tag == "div":
            self._depth += 1
            if "dex-card-kicker" in classes:
                self._kicker_depth = self._depth
            if "dex-card-name" in classes:
                self._name_depth = self._depth
        elif tag == "a" and self._name_depth is not None and attrs.get("title"):
            self._title = attrs["title"]

    def handle_data(self, data: str) -> None:
        if self._card_attributes is not None and self._kicker_depth is not None:
            self._kicker_text.append(data)

    def handle_endtag(self, tag: str) -> None:
        if self._card_attributes is None or tag != "div":
            return
        if self._kicker_depth == self._depth:
            self._kicker_depth = None
        if self._name_depth == self._depth:
            self._name_depth = None
        self._depth -= 1
        if self._depth != 0:
            return

        number_match = _NUMBER.search("".join(self._kicker_text))
        if self._title is None or number_match is None:
            raise AdapterError("Rendered pet card is missing a title or display number")
        self.cards.append(
            _RenderedCard(
                title=self._title,
                display_number=number_match.group(1),
                is_main_form=(
                    self._card_attributes.get("data-param5") == _MAIN_FORM_MARKER
                ),
            )
        )
        self._card_attributes = None


def inspect_rendered_pet_index(
    response_path: Path,
    core: CoreInspection,
) -> RenderedIndexInspection:
    try:
        raw_bytes = response_path.read_bytes()
        document = json.loads(raw_bytes)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise AdapterError(
            f"Cannot read rendered pet index response {response_path}: {error}"
        ) from error

    if not isinstance(document, dict) or document.get("error") is not None:
        raise AdapterError("Rendered pet index response contains an API error")
    parsed = document.get("parse")
    if not isinstance(parsed, dict):
        raise AdapterError("Rendered pet index response has no parse object")
    page_id = parsed.get("pageid")
    revision_id = parsed.get("revid")
    page_title = parsed.get("title")
    html = parsed.get("text")
    if (
        not isinstance(page_id, int)
        or isinstance(page_id, bool)
        or page_id <= 0
        or not isinstance(revision_id, int)
        or isinstance(revision_id, bool)
        or revision_id <= 0
        or not isinstance(page_title, str)
        or not page_title
        or not isinstance(html, str)
    ):
        raise AdapterError("Rendered pet index response has invalid page metadata or HTML")

    parser = _CardParser()
    try:
        parser.feed(html)
        parser.close()
    except (ValueError, AssertionError) as error:
        raise AdapterError(f"Cannot parse rendered pet index HTML: {error}") from error
    if parser._card_attributes is not None:
        raise AdapterError("Rendered pet index ended inside a pet card")
    if not parser.cards:
        raise AdapterError("Rendered pet index contains no pet cards")

    title_to_pet: dict[str, str] = {}
    for pet_id, record in core.records.items():
        title = require_string(record.get("title"), f"core.{pet_id}.title")
        if title in title_to_pet:
            raise AdapterError(f"Core contains duplicate page title {title!r}")
        title_to_pet[title] = pet_id

    unknown_titles: list[str] = []
    rendered_pet_ids: set[str] = set()
    main_pet_by_handbook: dict[str, str] = {}
    display_numbers: dict[str, set[str]] = {}
    for card in parser.cards:
        pet_id = title_to_pet.get(card.title)
        if pet_id is None:
            unknown_titles.append(card.title)
            continue
        if pet_id in rendered_pet_ids:
            raise AdapterError(f"Rendered pet index repeats Core title {card.title!r}")
        rendered_pet_ids.add(pet_id)
        handbook_value = core.records[pet_id].get("handbook")
        if handbook_value is None:
            continue
        handbook_id = require_string(
            require_mapping(handbook_value, f"core.{pet_id}.handbook").get("id"),
            f"core.{pet_id}.handbook.id",
        )
        display_numbers.setdefault(handbook_id, set()).add(card.display_number)
        if card.is_main_form:
            if handbook_id in main_pet_by_handbook:
                raise AdapterError(
                    f"Rendered pet index marks multiple main forms for {handbook_id}"
                )
            main_pet_by_handbook[handbook_id] = pet_id

    inconsistent_numbers = {
        handbook_id: sorted(numbers)
        for handbook_id, numbers in display_numbers.items()
        if len(numbers) != 1
    }
    if unknown_titles:
        raise AdapterError(
            "Rendered pet index contains titles missing from Core: "
            + ", ".join(sorted(unknown_titles))
        )
    if inconsistent_numbers:
        raise AdapterError(
            "Rendered pet index has inconsistent display numbers for shared handbook IDs"
        )

    display_number_by_handbook = {
        handbook_id: next(iter(numbers))
        for handbook_id, numbers in display_numbers.items()
    }
    topic_marked = set()
    for pet_id, record in core.records.items():
        handbook_value = record.get("handbook")
        if handbook_value is None:
            continue
        handbook = require_mapping(handbook_value, f"core.{pet_id}.handbook")
        if handbook.get("show_topics") is True:
            topic_marked.add(pet_id)

    return RenderedIndexInspection(
        report={
            "response_file": response_path.name,
            "response_bytes": len(raw_bytes),
            "response_sha256": hashlib.sha256(raw_bytes).hexdigest(),
            "page_title": page_title,
            "page_id": page_id,
            "page_revision_id": revision_id,
            "card_count": len(parser.cards),
            "mapped_card_count": len(rendered_pet_ids),
            "core_pet_ids_not_rendered": sorted(set(core.records) - rendered_pet_ids),
            "main_form_count": len(main_pet_by_handbook),
            "display_number_count": len(display_number_by_handbook),
            "display_numbers": dict(sorted(display_number_by_handbook.items())),
            "show_topics_main_form_correlation": {
                "matching_pet_count": len(topic_marked & set(main_pet_by_handbook.values())),
                "show_topics_only_pet_ids": sorted(
                    topic_marked - set(main_pet_by_handbook.values())
                ),
                "rendered_main_only_pet_ids": sorted(
                    set(main_pet_by_handbook.values()) - topic_marked
                ),
                "usage": "Diagnostic only; this flag is not a default-form rule.",
            },
        },
        main_pet_by_handbook=main_pet_by_handbook,
        display_number_by_handbook=display_number_by_handbook,
    )
