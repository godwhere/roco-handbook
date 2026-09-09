from __future__ import annotations


class CatalogToolError(Exception):
    exit_code = 1
    error_code = "catalog_error"

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


class LuaSyntaxError(CatalogToolError):
    exit_code = 3
    error_code = "unsafe_or_unsupported_lua"


class AdapterError(CatalogToolError):
    exit_code = 4
    error_code = "adapter_error"


class ReportWriteError(CatalogToolError):
    exit_code = 5
    error_code = "report_write_error"


class BuildBlockedError(CatalogToolError):
    exit_code = 6
    error_code = "build_blocked"
