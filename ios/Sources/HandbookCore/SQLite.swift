import Foundation
import CSystem

public struct HandbookError: Error, LocalizedError, Sendable {
    public let code: String
    public let message: String
    public init(_ code: String, _ message: String) {
        self.code = code
        self.message = message
    }
    public var errorDescription: String? { message }
}

enum SQLValue: Equatable {
    case text(String), integer(Int), real(Double), null
    var string: String? {
        if case .text(let value) = self { return value }
        return nil
    }
    var int: Int? {
        if case .integer(let value) = self { return value }
        return nil
    }
    var number: Double? {
        switch self {
        case .integer(let value): return Double(value)
        case .real(let value): return value
        default: return nil
        }
    }
}

typealias SQLRow = [String: SQLValue]
extension Dictionary where Key == String, Value == SQLValue {
    func text(_ key: String) -> String { self[key]?.string ?? "" }
    func optionalText(_ key: String) -> String? { self[key]?.string }
    func integer(_ key: String) -> Int? { self[key]?.int }
    func bool(_ key: String) -> Bool? { integer(key).map { $0 == 1 } }
}

final class SQLite {
    private var handle: OpaquePointer?
    init(_ url: URL, readOnly: Bool, create: Bool = false) throws {
        let flags = readOnly ? SQLITE_OPEN_READONLY :
            SQLITE_OPEN_READWRITE | (create ? SQLITE_OPEN_CREATE : 0)
        guard sqlite3_open_v2(url.path, &handle, flags | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            if let handle { sqlite3_close(handle) }
            handle = nil
            throw HandbookError("database_open", "The database could not be opened.")
        }
        sqlite3_busy_timeout(handle, 3000)
        do {
            try execute("PRAGMA foreign_keys = ON")
            if readOnly { try execute("PRAGMA query_only = ON") }
        } catch {
            sqlite3_close(handle)
            handle = nil
            throw error
        }
    }
    deinit { sqlite3_close(handle) }

    func executeScript(_ sql: String) throws {
        guard sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK else { throw failure() }
    }
    func execute(_ sql: String, _ arguments: [SQLValue] = []) throws {
        _ = try rows(sql, arguments)
    }
    func rows(_ sql: String, _ arguments: [SQLValue] = []) throws -> [SQLRow] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else { throw failure() }
        defer { sqlite3_finalize(statement) }
        guard Int(sqlite3_bind_parameter_count(statement)) == arguments.count else {
            throw HandbookError("database_binding", "The query arguments do not match.")
        }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for (index, argument) in arguments.enumerated() {
            let slot = Int32(index + 1)
            let code: Int32
            switch argument {
            case .text(let value):
                code = value.withCString { sqlite3_bind_text(statement, slot, $0, -1, transient) }
            case .integer(let value): code = sqlite3_bind_int64(statement, slot, Int64(value))
            case .real(let value): code = sqlite3_bind_double(statement, slot, value)
            case .null: code = sqlite3_bind_null(statement, slot)
            }
            guard code == SQLITE_OK else { throw failure() }
        }
        var result: [SQLRow] = []
        while true {
            let step = sqlite3_step(statement)
            if step == SQLITE_DONE { return result }
            guard step == SQLITE_ROW else { throw failure() }
            var row: SQLRow = [:]
            for column in 0..<sqlite3_column_count(statement) {
                let name = String(cString: sqlite3_column_name(statement, column))
                switch sqlite3_column_type(statement, column) {
                case SQLITE_INTEGER: row[name] = .integer(Int(sqlite3_column_int64(statement, column)))
                case SQLITE_FLOAT: row[name] = .real(sqlite3_column_double(statement, column))
                case SQLITE_TEXT:
                    let count = Int(sqlite3_column_bytes(statement, column))
                    let bytes = UnsafeBufferPointer(start: sqlite3_column_text(statement, column), count: count)
                    row[name] = .text(String(decoding: bytes, as: UTF8.self))
                default: row[name] = .null
                }
            }
            result.append(row)
        }
    }
    func transaction<T>(_ operation: () throws -> T) throws -> T {
        try execute("BEGIN IMMEDIATE")
        do {
            let result = try operation()
            try execute("COMMIT")
            return result
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }
    private func failure() -> HandbookError {
        HandbookError("database_query", "The local database operation failed.")
    }
}

func placeholders(_ count: Int) -> String { Array(repeating: "?", count: count).joined(separator: ",") }
func escapedLike(_ text: String) -> String {
    text.replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "%", with: "\\%")
        .replacingOccurrences(of: "_", with: "\\_")
}
func utcNow() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: Date())
}
