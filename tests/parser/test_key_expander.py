import unittest

from catalog_builder.errors import AdapterError
from catalog_builder.key_expander import expand_metadata_keys
from catalog_builder.lua_parser import LuaTable, parse_lua_table


class KeyExpanderTests(unittest.TestCase):
    def test_expands_keys_recursively_without_changing_values(self) -> None:
        root = parse_lua_table(
            'return {_meta={key={n="name",st="stats",hp="hp"}},'
            'pet_1={n="n",st={hp=100}}}'
        ).value
        result = expand_metadata_keys(root)
        pet = result.table.as_mapping("root")["pet_1"].as_mapping("pet")
        self.assertEqual("n", pet["name"])
        self.assertEqual(100, pet["stats"].as_mapping("stats")["hp"])
        metadata = result.table.as_mapping("root")["_meta"].as_mapping("_meta")
        self.assertIn("n", metadata["key"].as_mapping("key"))

    def test_rejects_expansion_collisions(self) -> None:
        root = parse_lua_table(
            'return {_meta={key={n="name"}},pet_1={n="first",name="second"}}'
        ).value
        with self.assertRaisesRegex(AdapterError, "duplicate key"):
            expand_metadata_keys(root)

    def test_no_metadata_mapping_is_a_no_op(self) -> None:
        root = parse_lua_table("return {item={name='value'}}").value
        result = expand_metadata_keys(root)
        self.assertEqual({}, result.mapping)
        self.assertIsInstance(result.table, LuaTable)


if __name__ == "__main__":
    unittest.main()
