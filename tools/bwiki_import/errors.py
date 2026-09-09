from __future__ import annotations


class ImportToolError(Exception):
    """Base class for an expected import failure."""

    exit_code = 1
    error_code = "import_error"

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


class InputError(ImportToolError):
    exit_code = 2
    error_code = "input_error"


class ResponseValidationError(ImportToolError):
    exit_code = 3
    error_code = "response_validation_error"


class SnapshotWriteError(ImportToolError):
    exit_code = 5
    error_code = "snapshot_write_error"
