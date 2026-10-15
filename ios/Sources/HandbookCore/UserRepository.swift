import Foundation
import Darwin

public actor UserRepository {
    public nonisolated let databaseURL: URL
    private let database: SQLite

    public init(supportURL: URL, schemaSQL: String) throws {
        let directory = supportURL.appendingPathComponent("user")
        try FileSafety.directory(supportURL)
        try FileSafety.directory(directory)
        databaseURL = directory.appendingPathComponent("user.db")
        let fd = Darwin.open(directory.appendingPathComponent("user_install.lock").path,
                             O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw HandbookError("user_lock", "Personal storage is unavailable.") }
        defer { Darwin.close(fd) }
        guard flock(fd, LOCK_EX) == 0 else { throw HandbookError("user_lock", "Personal storage is busy.") }
        defer { flock(fd, LOCK_UN) }
        if !FileManager.default.fileExists(atPath: databaseURL.path) {
            let staging = directory.appendingPathComponent(".native-user-\(UUID().uuidString).staging")
            defer { try? FileManager.default.removeItem(at: staging) }
            do {
                let candidate = try SQLite(staging, readOnly: false, create: true)
                try candidate.executeScript(schemaSQL)
                try candidate.execute("INSERT INTO user_meta(singleton, schema_version, created_at_utc) VALUES(1, 1, ?)", [.text(utcNow())])
                try Self.validate(candidate)
            }
            try FileManager.default.moveItem(at: staging, to: databaseURL)
        }
        try FileSafety.regular(databaseURL)
        database = try SQLite(databaseURL, readOnly: false)
        try Self.validate(database)
    }
    private static func validate(_ db: SQLite) throws {
        let tables: Set<String> = ["user_meta", "favorites", "collection_marks", "notes", "settings"]
        let actual = try db.rows("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'").map { $0.text("name") }
        let indexes = try db.rows("SELECT name FROM sqlite_master WHERE type = 'index' AND name NOT LIKE 'sqlite_%'").map { $0.text("name") }
        let meta = try db.rows("SELECT * FROM user_meta WHERE singleton = 1")
        let integrity = try db.rows("PRAGMA integrity_check")
        guard Set(actual) == tables, Set(indexes) == ["idx_favorites_created", "idx_notes_object"],
              try db.rows("PRAGMA user_version").first?.integer("user_version") == 1,
              meta.count == 1, meta[0].integer("schema_version") == 1,
              integrity.count == 1, integrity[0].text("integrity_check") == "ok",
              try db.rows("PRAGMA foreign_key_check").isEmpty else {
            throw HandbookError("user_schema", "The personal database is damaged or uses an unsupported schema. It has been preserved.")
        }
        for table in tables {
            guard try db.rows("PRAGMA foreign_key_list(\(table))").isEmpty else {
                throw HandbookError("user_foreign_key", "Personal storage must not reference the Catalog.")
            }
        }
    }
    private func arguments(_ ref: ObjectRef) throws -> [SQLValue] {
        guard ref.datasetID == "roco-world-zh-cn", !ref.objectID.isEmpty, !ref.name.isEmpty,
              !ref.objectID.contains("\0"), !ref.name.contains("\0") else {
            throw HandbookError("user_identity", "The saved reference is invalid.")
        }
        return [.text(ref.datasetID), .text(ref.type.rawValue), .text(ref.objectID)]
    }
    public func layout() throws -> PetCatalogLayout {
        guard let row = try database.rows("SELECT value_json FROM settings WHERE setting_key = ?", [.text("pet_catalog_layout")]).first,
              let string = try? JSONDecoder().decode(String.self, from: Data(row.text("value_json").utf8)),
              let layout = PetCatalogLayout(rawValue: string) else { return .threeColumn }
        return layout
    }
    public func setLayout(_ layout: PetCatalogLayout) throws {
        let json = String(decoding: try JSONEncoder().encode(layout.rawValue), as: UTF8.self)
        try database.execute("""
            INSERT INTO settings(setting_key, value_json, updated_at_utc) VALUES(?, ?, ?)
            ON CONFLICT(setting_key) DO UPDATE SET value_json = excluded.value_json, updated_at_utc = excluded.updated_at_utc
            """, [.text("pet_catalog_layout"), .text(json), .text(utcNow())])
    }
    public func isFavorite(_ object: ObjectRef) throws -> Bool {
        try !database.rows("SELECT 1 FROM favorites WHERE dataset_id = ? AND object_type = ? AND object_id = ?", arguments(object)).isEmpty
    }
    public func setFavorite(_ object: ObjectRef, enabled: Bool) throws {
        let args = try arguments(object)
        if enabled {
            try database.execute("""
                INSERT INTO favorites(dataset_id, object_type, object_id, name_snapshot, created_at_utc) VALUES(?, ?, ?, ?, ?)
                ON CONFLICT(dataset_id, object_type, object_id) DO UPDATE SET name_snapshot = excluded.name_snapshot
                """, args + [.text(object.name), .text(utcNow())])
        } else {
            try database.execute("DELETE FROM favorites WHERE dataset_id = ? AND object_type = ? AND object_id = ?", args)
        }
    }
    public func isCollected(_ handbookID: String, datasetID: String = "roco-world-zh-cn") throws -> Bool {
        try !database.rows("SELECT 1 FROM collection_marks WHERE dataset_id = ? AND handbook_id = ? AND collected = 1",
                          [.text(datasetID), .text(handbookID)]).isEmpty
    }
    public func setCollected(_ handbookID: String, name: String, collected: Bool, datasetID: String = "roco-world-zh-cn") throws {
        _ = try arguments(ObjectRef(datasetID: datasetID, type: .handbook, objectID: handbookID, name: name))
        try database.execute("""
            INSERT INTO collection_marks(dataset_id, handbook_id, collected, name_snapshot, updated_at_utc) VALUES(?, ?, ?, ?, ?)
            ON CONFLICT(dataset_id, handbook_id) DO UPDATE SET collected = excluded.collected,
            name_snapshot = excluded.name_snapshot, updated_at_utc = excluded.updated_at_utc
            """, [.text(datasetID), .text(handbookID), .integer(collected ? 1 : 0), .text(name), .text(utcNow())])
    }
    public func favorites() throws -> [FavoriteItem] {
        try database.rows("SELECT * FROM favorites ORDER BY created_at_utc DESC, dataset_id, object_type, object_id").map {
            FavoriteItem(object: try object($0), createdAt: $0.text("created_at_utc"))
        }
    }
    public func collectionMarks(datasetID: String = "roco-world-zh-cn") throws -> [CollectionMark] {
        try database.rows("SELECT * FROM collection_marks WHERE dataset_id = ? AND collected = 1 ORDER BY updated_at_utc DESC, handbook_id",
                          [.text(datasetID)]).map {
            CollectionMark(datasetID: $0.text("dataset_id"), handbookID: $0.text("handbook_id"),
                           name: $0.text("name_snapshot"), updatedAt: $0.text("updated_at_utc"))
        }
    }
    public func notes(_ ref: ObjectRef) throws -> [PersonalNote] {
        try database.rows("""
            SELECT * FROM notes WHERE dataset_id = ? AND object_type = ? AND object_id = ?
            ORDER BY updated_at_utc DESC, note_id
            """, arguments(ref)).map {
                PersonalNote(id: $0.text("note_id"), object: try object($0), content: $0.text("content"),
                             createdAt: $0.text("created_at_utc"), updatedAt: $0.text("updated_at_utc"))
            }
    }
    @discardableResult public func saveNote(_ ref: ObjectRef, content: String, id: String? = nil) throws -> String {
        let args = try arguments(ref)
        let text = content
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !text.contains("\0") else {
            throw HandbookError("note_content", "A note must contain text.")
        }
        let now = utcNow()
        let noteID = id ?? UUID().uuidString.lowercased()
        try database.transaction {
            if id != nil {
                let found = try database.rows("SELECT 1 FROM notes WHERE note_id = ? AND dataset_id = ? AND object_type = ? AND object_id = ?",
                                              [.text(noteID)] + args)
                guard !found.isEmpty else { throw HandbookError("note_identity", "The note does not belong to this saved item.") }
                try database.execute("""
                    UPDATE notes SET content = ?, name_snapshot = ?, updated_at_utc = ? WHERE note_id = ?
                    """, [.text(text), .text(ref.name), .text(now), .text(noteID)])
            } else {
                try database.execute("""
                    INSERT INTO notes(note_id, dataset_id, object_type, object_id, name_snapshot, content, created_at_utc, updated_at_utc)
                    VALUES(?, ?, ?, ?, ?, ?, ?, ?)
                    """, [.text(noteID)] + args + [.text(ref.name), .text(text), .text(now), .text(now)])
            }
        }
        return noteID
    }
    public func deleteNote(_ id: String) throws {
        try database.execute("DELETE FROM notes WHERE note_id = ?", [.text(id)])
    }
    private func object(_ row: SQLRow) throws -> ObjectRef {
        guard let type = UserObjectType(rawValue: row.text("object_type")) else {
            throw HandbookError("object_type", "A saved object type is unsupported. Its data has been preserved.")
        }
        return ObjectRef(datasetID: row.text("dataset_id"), type: type, objectID: row.text("object_id"), name: row.text("name_snapshot"))
    }
}
