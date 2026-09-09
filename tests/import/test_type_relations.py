from __future__ import annotations

import unittest
import json
from pathlib import Path

from bwiki_import.errors import ResponseValidationError
from bwiki_import.type_relations import parse_type_relations


RELATIONS = {
    "strong_against": "strong",
    "resisted_by": "blocked",
    "weak_to": "weak",
    "resists": "resists",
}
ROOT = Path(__file__).resolve().parents[2]


def _module(first_value: str = '{"B"}') -> str:
    return f"""
local helper = {{ignored = true}}
local type_relations = {{
  A = {{strong = {first_value}, blocked = {{}}, weak = {{}}, resists = {{}}}},
  B = {{strong = {{}}, blocked = {{}}, weak = {{"A"}}, resists = {{}}}},
}}
local executable_code = function() return true end
return executable_code
"""


class TypeRelationImportTests(unittest.TestCase):
    def test_frozen_contract_keeps_current_source_and_reviewed_conflicts(self) -> None:
        contract = json.loads(
            (ROOT / "app/assets/wiki/type-relations-v1.json").read_text(
                encoding="utf-8"
            )
        )

        self.assertEqual(39538, contract["source"]["revision_id"])
        self.assertEqual(19, len(contract["relations"]))
        self.assertEqual(8, len(contract["reviewed_reciprocity_exceptions"]))
        self.assertEqual(
            ["\u5149", "\u5730", "\u6c34"],
            contract["relations"]["\u8349"]["strong_against"],
        )

    def test_extracts_only_the_declared_data_table(self) -> None:
        result = parse_type_relations(
            _module(),
            source="Module:TypeRelation",
            type_order=["A", "B"],
            relation_names=RELATIONS,
        )

        self.assertEqual(["B"], result["A"]["strong_against"])
        self.assertEqual(["A"], result["B"]["weak_to"])

    def test_rejects_executable_syntax_inside_the_data_table(self) -> None:
        with self.assertRaisesRegex(ResponseValidationError, "unsupported"):
            parse_type_relations(
                _module("helper()"),
                source="Module:TypeRelation",
                type_order=["A", "B"],
                relation_names=RELATIONS,
            )

    def test_rejects_non_reciprocal_relationships(self) -> None:
        source = """
local type_relations = {
  A = {strong = {"B"}, blocked = {}, weak = {}, resists = {}},
  B = {strong = {}, blocked = {}, weak = {}, resists = {}},
}
return {}
"""
        with self.assertRaisesRegex(ResponseValidationError, "conflicts changed"):
            parse_type_relations(
                source,
                source="Module:TypeRelation",
                type_order=["A", "B"],
                relation_names=RELATIONS,
            )


if __name__ == "__main__":
    unittest.main()
