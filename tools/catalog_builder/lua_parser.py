from __future__ import annotations

from dataclasses import dataclass
import math
import re
from typing import TypeAlias, Union

from .errors import LuaSyntaxError


LuaScalar: TypeAlias = str | int | float | bool | None
LuaValue: TypeAlias = Union[LuaScalar, "LuaTable"]


@dataclass(frozen=True)
class SourcePosition:
    source: str
    line: int
    column: int
    offset: int

    def render(self) -> str:
        return f"{self.source}:{self.line}:{self.column}"


@dataclass(frozen=True)
class LuaField:
    key: LuaValue | None
    value: LuaValue
    position: SourcePosition
    implicit: bool


@dataclass(frozen=True)
class LuaTable:
    fields: tuple[LuaField, ...]
    position: SourcePosition

    @property
    def kind(self) -> str:
        if not self.fields:
            return "empty"
        implicit_count = sum(field.implicit for field in self.fields)
        if implicit_count == len(self.fields):
            return "array"
        if implicit_count == 0:
            return "map"
        return "mixed"

    def resolved_items(self) -> tuple[tuple[LuaScalar, LuaValue], ...]:
        next_array_index = 1
        result: list[tuple[LuaScalar, LuaValue]] = []
        seen: set[tuple[type[object], object]] = set()
        for field in self.fields:
            if field.implicit:
                key: LuaScalar = next_array_index
                next_array_index += 1
            else:
                if isinstance(field.key, LuaTable) or field.key is None:
                    raise LuaSyntaxError(
                        f"{field.position.render()}: table keys must be non-null scalars"
                    )
                key = field.key
            identity = (type(key), key)
            if identity in seen:
                raise LuaSyntaxError(
                    f"{field.position.render()}: duplicate table key {key!r}"
                )
            seen.add(identity)
            result.append((key, field.value))
        return tuple(result)

    def as_mapping(self, context: str) -> dict[str, LuaValue]:
        if self.kind not in {"map", "empty"}:
            raise LuaSyntaxError(f"{context}: expected a keyed table, found {self.kind}")
        result: dict[str, LuaValue] = {}
        for key, value in self.resolved_items():
            if not isinstance(key, str):
                raise LuaSyntaxError(f"{context}: expected string key, found {key!r}")
            result[key] = value
        return result

    def as_sequence(self, context: str) -> tuple[LuaValue, ...]:
        if self.kind not in {"array", "empty"}:
            raise LuaSyntaxError(f"{context}: expected an array table, found {self.kind}")
        return tuple(value for _, value in self.resolved_items())


@dataclass(frozen=True)
class LuaParseResult:
    value: LuaTable
    token_count: int
    max_depth: int


@dataclass(frozen=True)
class _Token:
    kind: str
    value: LuaScalar
    position: SourcePosition


_NUMBER = re.compile(
    r"(?:0[xX](?:[0-9a-fA-F]+(?:\.[0-9a-fA-F]*)?|\.[0-9a-fA-F]+)"
    r"(?:[pP][+-]?\d+)?|(?:\d+\.\d*|\.\d+|\d+)(?:[eE][+-]?\d+)?)"
)
_IDENTIFIER = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
_KEYWORDS = {
    "return": "RETURN",
    "true": "TRUE",
    "false": "FALSE",
    "nil": "NIL",
}
_PUNCTUATION = {
    "{": "LBRACE",
    "}": "RBRACE",
    "[": "LBRACKET",
    "]": "RBRACKET",
    "=": "EQUALS",
    ",": "COMMA",
    ";": "SEMICOLON",
    "-": "MINUS",
}


class _Lexer:
    def __init__(self, text: str, source: str, max_tokens: int) -> None:
        self.text = text
        self.source = source
        self.max_tokens = max_tokens
        self.index = 0
        self.line = 1
        self.column = 1
        self.tokens: list[_Token] = []

    def _position(self) -> SourcePosition:
        return SourcePosition(self.source, self.line, self.column, self.index)

    def _advance(self, count: int = 1) -> str:
        consumed = self.text[self.index : self.index + count]
        for character in consumed:
            if character == "\n":
                self.line += 1
                self.column = 1
            else:
                self.column += 1
        self.index += count
        return consumed

    def _error(self, message: str, position: SourcePosition | None = None) -> LuaSyntaxError:
        location = position or self._position()
        return LuaSyntaxError(f"{location.render()}: {message}")

    def _long_bracket_level(self) -> int | None:
        if self.index >= len(self.text) or self.text[self.index] != "[":
            return None
        cursor = self.index + 1
        while cursor < len(self.text) and self.text[cursor] == "=":
            cursor += 1
        if cursor < len(self.text) and self.text[cursor] == "[":
            return cursor - self.index - 1
        return None

    def _read_long_body(self, level: int) -> str:
        opener_length = level + 2
        self._advance(opener_length)
        closing = "]" + ("=" * level) + "]"
        end = self.text.find(closing, self.index)
        if end < 0:
            raise self._error("unterminated long bracket")
        body = self.text[self.index : end]
        self._advance(end - self.index)
        self._advance(len(closing))
        if body.startswith("\r\n"):
            body = body[2:]
        elif body.startswith("\n") or body.startswith("\r"):
            body = body[1:]
        return body

    def _skip_space_and_comments(self) -> None:
        while self.index < len(self.text):
            if self.text[self.index].isspace():
                self._advance()
                continue
            if self.text.startswith("--", self.index):
                self._advance(2)
                level = self._long_bracket_level()
                if level is not None:
                    self._read_long_body(level)
                else:
                    while self.index < len(self.text) and self.text[self.index] not in "\r\n":
                        self._advance()
                continue
            break

    def _read_short_string(self) -> str:
        quote = self.text[self.index]
        start = self._position()
        self._advance()
        result: list[str] = []
        simple_escapes = {
            "a": "\a",
            "b": "\b",
            "f": "\f",
            "n": "\n",
            "r": "\r",
            "t": "\t",
            "v": "\v",
            "\\": "\\",
            '"': '"',
            "'": "'",
        }
        while self.index < len(self.text):
            character = self.text[self.index]
            if character == quote:
                self._advance()
                return "".join(result)
            if character in "\r\n":
                raise self._error("newline in short string", start)
            if character != "\\":
                result.append(self._advance())
                continue

            self._advance()
            if self.index >= len(self.text):
                raise self._error("unterminated escape sequence", start)
            escape = self.text[self.index]
            if escape in simple_escapes:
                self._advance()
                result.append(simple_escapes[escape])
            elif escape in "\r\n":
                if escape == "\r" and self.text.startswith("\r\n", self.index):
                    self._advance(2)
                else:
                    self._advance()
                result.append("\n")
            elif escape == "z":
                self._advance()
                while self.index < len(self.text) and self.text[self.index].isspace():
                    self._advance()
            elif escape == "x":
                self._advance()
                digits = self.text[self.index : self.index + 2]
                if len(digits) != 2 or not re.fullmatch(r"[0-9a-fA-F]{2}", digits):
                    raise self._error("invalid hexadecimal string escape")
                self._advance(2)
                result.append(chr(int(digits, 16)))
            elif escape == "u":
                self._advance()
                match = re.match(r"\{([0-9a-fA-F]+)\}", self.text[self.index :])
                if not match:
                    raise self._error("invalid Unicode string escape")
                codepoint = int(match.group(1), 16)
                if codepoint > 0x10FFFF:
                    raise self._error("Unicode escape is out of range")
                self._advance(len(match.group(0)))
                result.append(chr(codepoint))
            elif escape.isdigit():
                match = re.match(r"\d{1,3}", self.text[self.index :])
                assert match is not None
                value = int(match.group(0), 10)
                if value > 255:
                    raise self._error("decimal string escape is out of range")
                self._advance(len(match.group(0)))
                result.append(chr(value))
            else:
                raise self._error(f"unsupported string escape \\{escape}")
        raise self._error("unterminated short string", start)

    def _read_number(self) -> int | float:
        match = _NUMBER.match(self.text, self.index)
        if not match:
            raise self._error("invalid numeric literal")
        raw = match.group(0)
        self._advance(len(raw))
        lowered = raw.lower()
        if lowered.startswith("0x"):
            value: int | float = (
                float.fromhex(raw) if ("." in raw or "p" in lowered) else int(raw, 16)
            )
        elif any(marker in lowered for marker in (".", "e")):
            value = float(raw)
        else:
            value = int(raw, 10)
        if isinstance(value, float) and not math.isfinite(value):
            raise self._error("non-finite numeric literal")
        return value

    def tokenize(self) -> tuple[_Token, ...]:
        if self.text.startswith("\ufeff"):
            self._advance()
        while True:
            self._skip_space_and_comments()
            if self.index >= len(self.text):
                self.tokens.append(_Token("EOF", None, self._position()))
                return tuple(self.tokens)
            position = self._position()
            character = self.text[self.index]

            if character in {'"', "'"}:
                token = _Token("STRING", self._read_short_string(), position)
            elif character == "[" and (level := self._long_bracket_level()) is not None:
                token = _Token("STRING", self._read_long_body(level), position)
            elif character.isdigit() or (
                character == "."
                and self.index + 1 < len(self.text)
                and self.text[self.index + 1].isdigit()
            ):
                token = _Token("NUMBER", self._read_number(), position)
            elif match := _IDENTIFIER.match(self.text, self.index):
                raw = match.group(0)
                self._advance(len(raw))
                token = _Token(_KEYWORDS.get(raw, "IDENTIFIER"), raw, position)
            elif character in _PUNCTUATION:
                self._advance()
                token = _Token(_PUNCTUATION[character], character, position)
            else:
                raise self._error(f"unsupported token {character!r}")

            self.tokens.append(token)
            if len(self.tokens) > self.max_tokens:
                raise self._error(f"token count exceeds limit {self.max_tokens}", position)


class _Parser:
    def __init__(self, tokens: tuple[_Token, ...], max_depth: int) -> None:
        self.tokens = tokens
        self.max_depth_allowed = max_depth
        self.index = 0
        self.depth = 0
        self.max_depth_seen = 0

    def _peek(self, offset: int = 0) -> _Token:
        return self.tokens[min(self.index + offset, len(self.tokens) - 1)]

    def _take(self, kind: str) -> _Token:
        token = self._peek()
        if token.kind != kind:
            raise LuaSyntaxError(
                f"{token.position.render()}: expected {kind}, found {token.kind}"
            )
        self.index += 1
        return token

    def parse(self) -> LuaParseResult:
        self._take("RETURN")
        value = self._parse_value()
        if not isinstance(value, LuaTable):
            raise LuaSyntaxError(
                f"{self._peek().position.render()}: top-level return value must be a table"
            )
        self._take("EOF")
        return LuaParseResult(value, len(self.tokens), self.max_depth_seen)

    def _parse_value(self) -> LuaValue:
        token = self._peek()
        if token.kind == "LBRACE":
            return self._parse_table()
        if token.kind in {"STRING", "NUMBER"}:
            self.index += 1
            return token.value
        if token.kind == "TRUE":
            self.index += 1
            return True
        if token.kind == "FALSE":
            self.index += 1
            return False
        if token.kind == "NIL":
            self.index += 1
            return None
        if token.kind == "MINUS":
            self.index += 1
            number = self._take("NUMBER").value
            assert isinstance(number, (int, float)) and not isinstance(number, bool)
            return -number
        raise LuaSyntaxError(
            f"{token.position.render()}: executable or unsupported value token {token.kind}"
        )

    def _parse_table(self) -> LuaTable:
        opener = self._take("LBRACE")
        self.depth += 1
        self.max_depth_seen = max(self.max_depth_seen, self.depth)
        if self.depth > self.max_depth_allowed:
            raise LuaSyntaxError(
                f"{opener.position.render()}: table nesting exceeds limit "
                f"{self.max_depth_allowed}"
            )
        fields: list[LuaField] = []
        try:
            while self._peek().kind != "RBRACE":
                start = self._peek().position
                if self._peek().kind == "LBRACKET":
                    self._take("LBRACKET")
                    key = self._parse_value()
                    self._take("RBRACKET")
                    self._take("EQUALS")
                    value = self._parse_value()
                    fields.append(LuaField(key, value, start, False))
                elif self._peek().kind == "IDENTIFIER" and self._peek(1).kind == "EQUALS":
                    key_token = self._take("IDENTIFIER")
                    self._take("EQUALS")
                    fields.append(
                        LuaField(str(key_token.value), self._parse_value(), start, False)
                    )
                else:
                    fields.append(LuaField(None, self._parse_value(), start, True))

                if self._peek().kind in {"COMMA", "SEMICOLON"}:
                    self.index += 1
                elif self._peek().kind != "RBRACE":
                    token = self._peek()
                    raise LuaSyntaxError(
                        f"{token.position.render()}: expected field separator or closing brace"
                    )
            self._take("RBRACE")
            table = LuaTable(tuple(fields), opener.position)
            table.resolved_items()
            return table
        finally:
            self.depth -= 1


def parse_lua_table(
    text: str,
    *,
    source: str = "<memory>",
    max_input_bytes: int = 8 * 1024 * 1024,
    max_tokens: int = 2_000_000,
    max_depth: int = 128,
) -> LuaParseResult:
    input_bytes = len(text.encode("utf-8"))
    if input_bytes > max_input_bytes:
        raise LuaSyntaxError(
            f"{source}:1:1: input size {input_bytes} exceeds limit {max_input_bytes}"
        )
    tokens = _Lexer(text, source, max_tokens).tokenize()
    return _Parser(tokens, max_depth).parse()
