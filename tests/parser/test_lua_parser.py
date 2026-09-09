import unittest

from catalog_builder.errors import LuaSyntaxError
from catalog_builder.lua_parser import LuaTable, parse_lua_table


class LuaParserTests(unittest.TestCase):
    def test_parses_data_only_table_without_executing_code(self) -> None:
        parsed = parse_lua_table(
            """
            -- line comment
            return {
              name = "Sample",
              enabled = true,
              disabled = false,
              missing = nil,
              signed = -12,
              ratio = 1.5e1,
              values = {1, 2, 3},
              nested = {key = 'value'},
            }
            """,
            source="sample.lua",
        )
        root = parsed.value.as_mapping("root")
        self.assertEqual("Sample", root["name"])
        self.assertEqual(-12, root["signed"])
        self.assertEqual(15.0, root["ratio"])
        self.assertEqual((1, 2, 3), root["values"].as_sequence("values"))
        self.assertEqual(
            "value",
            root["nested"].as_mapping("nested")["key"],
        )

    def test_preserves_empty_array_map_and_mixed_table_shapes(self) -> None:
        root = parse_lua_table(
            "return {empty={}, array={1,2}, map={a=1}, mixed={1,a=2}}"
        ).value.as_mapping("root")
        self.assertEqual("empty", root["empty"].kind)
        self.assertEqual("array", root["array"].kind)
        self.assertEqual("map", root["map"].kind)
        self.assertEqual("mixed", root["mixed"].kind)

    def test_supports_long_comments_strings_and_escape_sequences(self) -> None:
        root = parse_lua_table(
            r"""
            --[=[ ignored code: require("unsafe") ]=]
            return {
              long = [=[first
second]=],
              escaped = "line\n\x41\u{42}",
            }
            """
        ).value.as_mapping("root")
        self.assertEqual("first\nsecond", root["long"])
        self.assertEqual("line\nAB", root["escaped"])

    def test_rejects_duplicate_keys(self) -> None:
        with self.assertRaisesRegex(LuaSyntaxError, "duplicate table key"):
            parse_lua_table("return {same=1,same=2}", source="duplicate.lua")

    def test_rejects_function_calls(self) -> None:
        with self.assertRaisesRegex(LuaSyntaxError, "unsupported token"):
            parse_lua_table('return require("Module:Unsafe")', source="unsafe.lua")

    def test_rejects_local_statements(self) -> None:
        with self.assertRaisesRegex(LuaSyntaxError, "expected RETURN"):
            parse_lua_table("local value = {}; return value", source="unsafe.lua")

    def test_rejects_expressions_inside_fields(self) -> None:
        with self.assertRaisesRegex(LuaSyntaxError, "unsupported token"):
            parse_lua_table("return {answer=20+22}", source="unsafe.lua")

    def test_enforces_input_size_limit(self) -> None:
        with self.assertRaisesRegex(LuaSyntaxError, "input size"):
            parse_lua_table("return {}", max_input_bytes=4)

    def test_enforces_nesting_limit(self) -> None:
        with self.assertRaisesRegex(LuaSyntaxError, "nesting exceeds"):
            parse_lua_table("return {{{{1}}}}", max_depth=3)

    def test_reports_source_location_for_unsafe_tokens(self) -> None:
        with self.assertRaisesRegex(LuaSyntaxError, r"source.lua:2:14"):
            parse_lua_table("return {\n  answer = 1 + 2\n}", source="source.lua")


if __name__ == "__main__":
    unittest.main()
