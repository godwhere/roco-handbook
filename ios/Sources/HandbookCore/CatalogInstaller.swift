import Foundation
import CryptoKit
import Darwin

enum FileSafety {
    static func regular(_ url: URL) throws {
        let value = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
        guard value.isRegularFile == true, value.isSymbolicLink != true else {
            throw HandbookError("file_type", "The database or package file is not a regular file.")
        }
    }
    static func directory(_ url: URL) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) { try fm.createDirectory(at: url, withIntermediateDirectories: true) }
        let value = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        guard value.isDirectory == true, value.isSymbolicLink != true else {
            throw HandbookError("directory_type", "The private storage directory is not available.")
        }
    }
    static func write(_ data: Data, to target: URL) throws {
        let temporary = target.deletingLastPathComponent().appendingPathComponent(".native-\(UUID().uuidString).tmp")
        defer { try? FileManager.default.removeItem(at: temporary) }
        guard FileManager.default.createFile(atPath: temporary.path, contents: nil) else {
            throw HandbookError("file_write", "The private storage file could not be created.")
        }
        let handle = try FileHandle(forWritingTo: temporary)
        defer { try? handle.close() }
        try handle.write(contentsOf: data)
        try handle.synchronize()
        guard Darwin.rename(temporary.path, target.path) == 0 else {
            throw HandbookError("file_activate", "The private storage file could not be activated.")
        }
    }
}

func sha256(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
func strictObject(_ data: Data, fields: Set<String>, maximum: Int = 128 * 1024) throws -> [String: Any] {
    guard !data.isEmpty, data.count <= maximum,
          let value = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          Set(value.keys) == fields else {
        throw HandbookError("json_contract", "The package metadata has an invalid shape.")
    }
    return value
}
func jsonInt(_ value: Any?) -> Int? {
    guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
          number.doubleValue.isFinite, number.doubleValue == Double(number.intValue) else { return nil }
    return number.intValue
}
func validHash(_ value: String) -> Bool { value.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil }

public struct CatalogManifest: Equatable, Sendable {
    public let datasetId: String
    public let schemaVersion: Int
    public let dataVersion: Int
    public let snapshotId: String
    public let databaseBytes: Int
    public let databaseSha256: String
    public let coverage: [String: Bool]
    static let coverageFields: Set<String> = ["pets", "skills", "evolutions", "topic_rewards", "skill_stone_topics", "description_note_definitions"]

    public init(data: Data) throws {
        let raw = try strictObject(data, fields: [
            "manifest_version", "dataset_id", "catalog_schema_version", "data_version", "snapshot_id",
            "database_asset", "database_bytes", "database_sha256", "coverage",
        ], maximum: 64 * 1024)
        guard jsonInt(raw["manifest_version"]) == 1, raw["database_asset"] as? String == "assets/catalog/catalog.db",
              let dataset = raw["dataset_id"] as? String, let schema = jsonInt(raw["catalog_schema_version"]),
              let version = jsonInt(raw["data_version"]), let snapshot = raw["snapshot_id"] as? String,
              let bytes = jsonInt(raw["database_bytes"]), let hash = raw["database_sha256"] as? String else {
            throw HandbookError("manifest_contract", "The Catalog manifest is incompatible with this App.")
        }
        datasetId = dataset; schemaVersion = schema; dataVersion = version; snapshotId = snapshot
        databaseBytes = bytes; databaseSha256 = hash
        coverage = try Self.validateCoverage(raw["coverage"])
        try validate()
    }
    init(datasetId: String, schemaVersion: Int, dataVersion: Int, snapshotId: String,
         databaseBytes: Int, databaseSha256: String, coverage: [String: Bool]) throws {
        self.datasetId = datasetId; self.schemaVersion = schemaVersion; self.dataVersion = dataVersion
        self.snapshotId = snapshotId; self.databaseBytes = databaseBytes; self.databaseSha256 = databaseSha256
        self.coverage = coverage
        try validate()
    }
    static func validateCoverage(_ raw: Any?) throws -> [String: Bool] {
        guard let value = raw as? [String: Any], Set(value.keys) == coverageFields,
              value.values.allSatisfy({ ($0 as? NSNumber).map { CFGetTypeID($0) == CFBooleanGetTypeID() } ?? false }),
              let coverage = value as? [String: Bool], coverage["pets"] == true,
              coverage["skills"] == true, coverage["evolutions"] == true else {
            throw HandbookError("manifest_coverage", "The Catalog does not cover the required data.")
        }
        return coverage
    }
    private func validate() throws {
        guard datasetId == "roco-world-zh-cn", schemaVersion == 1, dataVersion > 0,
              databaseBytes > 0, databaseBytes <= 128 * 1024 * 1024, validHash(databaseSha256),
              snapshotId.range(of: "^snapshot-[0-9a-z-]{8,80}$", options: .regularExpression) != nil else {
            throw HandbookError("manifest_identity", "The Catalog manifest identity is incompatible with this App.")
        }
    }
    var filename: String { "catalog-v\(dataVersion)-s\(schemaVersion)-\(databaseSha256.prefix(12)).db" }
}

public struct CatalogBundle: Sendable {
    public let manifest: CatalogManifest
    public let database: Data
    public let attribution: Data
    public init(manifest: Data, database: Data, attribution: Data) throws {
        self.manifest = try CatalogManifest(data: manifest)
        self.database = database
        self.attribution = attribution
        try Self.validateAttribution(attribution)
    }
    public static func load(assetRoot: URL) throws -> CatalogBundle {
        let directory = assetRoot.appendingPathComponent("catalog")
        let urls = ["bundled_catalog.json", "catalog.db", "ATTRIBUTION.txt"].map { directory.appendingPathComponent($0) }
        for url in urls { try FileSafety.regular(url) }
        return try CatalogBundle(manifest: Data(contentsOf: urls[0]), database: Data(contentsOf: urls[1]), attribution: Data(contentsOf: urls[2]))
    }
    static func validateAttribution(_ data: Data) throws {
        guard data.count > 0, data.count <= 256 * 1024, let text = String(data: data, encoding: .utf8),
              !text.contains("\0"), text.hasPrefix("Roco World Offline Handbook - Catalog Attribution\n"),
              text.contains("\nSource: "), text.contains("\nLicense: "),
              text.contains("\nLicense URL: https://") else {
            throw HandbookError("attribution_contract", "The Catalog attribution is missing or invalid.")
        }
    }
}

struct CatalogDescriptor: Equatable {
    let manifest: CatalogManifest
    let attributionBytes: Int
    let attributionHash: String
    let filename: String
    init(_ bundle: CatalogBundle) {
        manifest = bundle.manifest; attributionBytes = bundle.attribution.count
        attributionHash = sha256(bundle.attribution); filename = bundle.manifest.filename
    }
    init(data: Data, bundled: CatalogBundle) throws {
        let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        if Set(raw.keys) == ["dataset_id", "schema_version", "data_version", "database_sha256"],
           raw["dataset_id"] as? String == bundled.manifest.datasetId,
           jsonInt(raw["schema_version"]) == bundled.manifest.schemaVersion,
           jsonInt(raw["data_version"]) == bundled.manifest.dataVersion,
           raw["database_sha256"] as? String == bundled.manifest.databaseSha256 {
            manifest = bundled.manifest
            attributionBytes = bundled.attribution.count
            attributionHash = sha256(bundled.attribution)
            filename = "catalog-v\(manifest.dataVersion)-s\(manifest.schemaVersion).db"
            return
        }
        let version = jsonInt(raw["pointer_version"])
        let common: Set<String> = ["pointer_version", "dataset_id", "schema_version", "data_version", "snapshot_id",
                                   "database_bytes", "database_sha256", "coverage", "file_name"]
        let fields = version == 2 ? common.union(["attribution_bytes", "attribution_sha256"]) : common
        guard (version == 1 || version == 2), Set(raw.keys) == fields,
              let dataset = raw["dataset_id"] as? String, let schema = jsonInt(raw["schema_version"]),
              let dataVersion = jsonInt(raw["data_version"]), let snapshot = raw["snapshot_id"] as? String,
              let bytes = jsonInt(raw["database_bytes"]), let hash = raw["database_sha256"] as? String,
              let name = raw["file_name"] as? String else {
            throw HandbookError("pointer_contract", "The Catalog pointer is invalid.")
        }
        manifest = try CatalogManifest(datasetId: dataset, schemaVersion: schema, dataVersion: dataVersion, snapshotId: snapshot,
                                       databaseBytes: bytes, databaseSha256: hash, coverage: CatalogManifest.validateCoverage(raw["coverage"]))
        guard name == manifest.filename || name == "catalog-v\(dataVersion)-s\(schema).db" else {
            throw HandbookError("pointer_path", "The Catalog pointer does not identify an allowed file.")
        }
        filename = name
        if version == 1 {
            guard manifest == bundled.manifest else {
                throw HandbookError("pointer_migration", "The legacy Catalog attribution cannot be reconstructed.")
            }
            attributionBytes = bundled.attribution.count; attributionHash = sha256(bundled.attribution)
        } else {
            guard let size = jsonInt(raw["attribution_bytes"]), size > 0, size <= 256 * 1024,
                  let hash = raw["attribution_sha256"] as? String, validHash(hash) else {
                throw HandbookError("pointer_attribution", "The Catalog attribution descriptor is invalid.")
            }
            attributionBytes = size; attributionHash = hash
        }
    }
    var attributionFilename: String { "\(filename.dropLast(3)).attribution.txt" }
    func sameArtifact(_ other: CatalogDescriptor) -> Bool {
        manifest == other.manifest && attributionBytes == other.attributionBytes && attributionHash == other.attributionHash
    }
    func data() throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "pointer_version": 2, "dataset_id": manifest.datasetId, "schema_version": manifest.schemaVersion,
            "data_version": manifest.dataVersion, "snapshot_id": manifest.snapshotId,
            "database_bytes": manifest.databaseBytes, "database_sha256": manifest.databaseSha256,
            "coverage": manifest.coverage, "file_name": filename,
            "attribution_bytes": attributionBytes, "attribution_sha256": attributionHash,
        ], options: [.sortedKeys, .withoutEscapingSlashes])
    }
}

public struct CatalogOpenResult: Sendable {
    public let databaseURL: URL
    public let manifest: CatalogManifest
    public let attribution: String
    public let outcome: String
}

public actor CatalogInstaller {
    public let supportURL: URL
    public init(supportURL: URL) { self.supportURL = supportURL }
    private var catalogs: URL { supportURL.appendingPathComponent("catalogs") }
    private var state: URL { supportURL.appendingPathComponent("catalog-state") }
    private var activePointer: URL { state.appendingPathComponent("active_catalog.json") }
    private var previousPointer: URL { state.appendingPathComponent("previous_catalog.json") }

    public func prepare(_ bundle: CatalogBundle, restore: Bool = false) throws -> CatalogOpenResult {
        try locked { try activate(bundle, restore: restore) }
    }
    func installRemote(_ bundle: CatalogBundle, sequence: Int) throws -> CatalogOpenResult {
        try locked {
            guard sequence > (try highestSequenceUnlocked()) else {
                throw HandbookError("release_sequence", "This Catalog release has already been accepted.")
            }
            guard let active = validated(readPointer(activePointer, bundled: bundle), bundled: bundle),
                  bundle.manifest.dataVersion > active.manifest.dataVersion else {
                throw HandbookError("remote_activation", "A newer Catalog and a validated active Catalog are required.")
            }
            return try activate(bundle, restore: false, sequence: sequence)
        }
    }
    public func highestSequence() throws -> Int {
        try locked { try highestSequenceUnlocked() }
    }
    private func highestSequenceUnlocked() throws -> Int {
        let file = state.appendingPathComponent("catalog_update_state.json")
        if !FileManager.default.fileExists(atPath: file.path) { return 0 }
        try FileSafety.regular(file)
        let raw = try strictObject(Data(contentsOf: file), fields: ["state_version", "highest_accepted_release_sequence"])
        guard jsonInt(raw["state_version"]) == 1, let sequence = jsonInt(raw["highest_accepted_release_sequence"]), sequence >= 0 else {
            throw HandbookError("sequence_state", "The Catalog update history is invalid.")
        }
        return sequence
    }
    private func locked<T>(_ body: () throws -> T) throws -> T {
        try FileSafety.directory(supportURL); try FileSafety.directory(catalogs); try FileSafety.directory(state)
        let lockURL = state.appendingPathComponent("catalog_install.lock")
        let fd = Darwin.open(lockURL.path, O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw HandbookError("catalog_lock", "Catalog storage is unavailable.") }
        defer { Darwin.close(fd) }
        guard flock(fd, LOCK_EX) == 0 else { throw HandbookError("catalog_lock", "Catalog storage is busy.") }
        defer { flock(fd, LOCK_UN) }
        return try body()
    }
    private func readPointer(_ url: URL, bundled: CatalogBundle) -> CatalogDescriptor? {
        guard (try? FileSafety.regular(url)) != nil,
              let data = try? Data(contentsOf: url), data.count <= 128 * 1024,
              let descriptor = try? CatalogDescriptor(data: data, bundled: bundled) else { return nil }
        return descriptor
    }
    private func validated(_ descriptor: CatalogDescriptor?, bundled: CatalogBundle) -> CatalogDescriptor? {
        guard let descriptor else { return nil }
        do {
            try Self.validateDatabase(catalogs.appendingPathComponent(descriptor.filename), manifest: descriptor.manifest)
            let attributionURL = catalogs.appendingPathComponent(descriptor.attributionFilename)
            if !FileManager.default.fileExists(atPath: attributionURL.path), descriptor.manifest == bundled.manifest {
                try FileSafety.write(bundled.attribution, to: attributionURL)
            }
            try validateAttribution(descriptor)
            return descriptor
        } catch { return nil }
    }
    private func activate(_ bundle: CatalogBundle, restore: Bool, sequence: Int? = nil) throws -> CatalogOpenResult {
        try CatalogBundle.validateAttribution(bundle.attribution)
        let candidate = CatalogDescriptor(bundle)
        let active = validated(readPointer(activePointer, bundled: bundle), bundled: bundle)
        let previous = validated(readPointer(previousPointer, bundled: bundle), bundled: bundle)
        let fallback = active ?? previous
        if !restore, let fallback {
            if fallback.manifest.dataVersion == bundle.manifest.dataVersion, !fallback.sameArtifact(candidate) {
                throw HandbookError("version_collision", "This data version identifies a different Catalog artifact.")
            }
            if fallback.manifest.dataVersion >= bundle.manifest.dataVersion {
                try FileSafety.write(fallback.data(), to: activePointer)
                return try result(fallback, outcome: active == nil ? "Recovered the previous validated Catalog" : "Opened the current validated Catalog")
            }
        }
        guard bundle.database.count == bundle.manifest.databaseBytes, sha256(bundle.database) == bundle.manifest.databaseSha256 else {
            throw HandbookError("database_hash", "The Catalog bytes do not match the manifest.")
        }
        let target = catalogs.appendingPathComponent(candidate.filename)
        let staging = catalogs.appendingPathComponent(".native-\(UUID().uuidString).staging.db")
        defer { try? FileManager.default.removeItem(at: staging) }
        try FileSafety.write(bundle.database, to: staging)
        try Self.validateDatabase(staging, manifest: bundle.manifest)
        if FileManager.default.fileExists(atPath: target.path) {
            do { try Self.validateDatabase(target, manifest: bundle.manifest) }
            catch {
                // A failed target may be replaced only at this exact hash-qualified basename.
                try FileSafety.regular(target)
                try FileManager.default.removeItem(at: target)
                try FileManager.default.moveItem(at: staging, to: target)
            }
        } else { try FileManager.default.moveItem(at: staging, to: target) }
        try FileSafety.write(bundle.attribution, to: catalogs.appendingPathComponent(candidate.attributionFilename))
        if let fallback, !fallback.sameArtifact(candidate) { try FileSafety.write(fallback.data(), to: previousPointer) }
        // Reject invalid packages before advancing the replay floor. Once fully validated,
        // acceptance is durable before the pointer switch and recovery never lowers it.
        if let sequence {
            try FileSafety.write(JSONSerialization.data(withJSONObject: [
                "state_version": 1, "highest_accepted_release_sequence": sequence,
            ], options: .sortedKeys), to: state.appendingPathComponent("catalog_update_state.json"))
        }
        do {
            try FileSafety.write(candidate.data(), to: activePointer)
            return try result(candidate, outcome: restore ? "Restored the Catalog bundled with this App" : "Installed bundled Catalog data")
        } catch {
            if let fallback { try FileSafety.write(fallback.data(), to: activePointer) }
            throw error
        }
    }
    private func validateAttribution(_ descriptor: CatalogDescriptor) throws {
        let file = catalogs.appendingPathComponent(descriptor.attributionFilename)
        try FileSafety.regular(file)
        let bytes = try Data(contentsOf: file)
        guard bytes.count == descriptor.attributionBytes, sha256(bytes) == descriptor.attributionHash else {
            throw HandbookError("attribution_hash", "The installed Catalog attribution is damaged.")
        }
        try CatalogBundle.validateAttribution(bytes)
    }
    private func result(_ descriptor: CatalogDescriptor, outcome: String) throws -> CatalogOpenResult {
        let url = catalogs.appendingPathComponent(descriptor.filename)
        try Self.validateDatabase(url, manifest: descriptor.manifest)
        try validateAttribution(descriptor)
        let attribution = try String(contentsOf: catalogs.appendingPathComponent(descriptor.attributionFilename), encoding: .utf8)
        return CatalogOpenResult(databaseURL: url, manifest: descriptor.manifest, attribution: attribution, outcome: outcome)
    }
    static func validateDatabase(_ url: URL, manifest: CatalogManifest) throws {
        try FileSafety.regular(url)
        let data = try Data(contentsOf: url)
        guard data.count == manifest.databaseBytes, sha256(data) == manifest.databaseSha256 else {
            throw HandbookError("database_hash", "The Catalog database does not match its manifest.")
        }
        let db = try SQLite(url, readOnly: true)
        let meta = try db.rows("SELECT * FROM catalog_meta WHERE singleton = 1")
        guard meta.count == 1, let row = meta.first, row.text("dataset_id") == manifest.datasetId,
              row.integer("schema_version") == manifest.schemaVersion, row.integer("data_version") == manifest.dataVersion,
              row.text("snapshot_id") == manifest.snapshotId, try db.rows("PRAGMA user_version").first?.integer("user_version") == 1,
              try JSONDecoder().decode([String: Bool].self, from: Data(row.text("coverage_json").utf8)) == manifest.coverage else {
            throw HandbookError("database_metadata", "Catalog metadata does not match its manifest.")
        }
        let objects = try db.rows("SELECT name, type FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'")
        let tables = Set(objects.filter { $0.text("type") == "table" }.map { $0.text("name") })
        let views = Set(objects.filter { $0.text("type") == "view" }.map { $0.text("name") })
        let required: Set<String> = ["catalog_meta", "source_revisions", "handbook_entries", "types", "skills",
            "skill_description_notes", "pets", "handbook_display", "pet_aliases", "pet_types", "learnsets", "pet_learnsets",
            "learnset_native_skills", "learnset_blood_skills", "learnset_skill_stones", "learnset_legendary_skills",
            "evolution_groups", "pet_evolution_groups", "evolution_edges", "entity_sources"]
        let integrity = try db.rows("PRAGMA integrity_check")
        let probe = try db.rows("""
            SELECT h.dex_no, f.skill_id FROM pets p JOIN handbook_entries h ON h.handbook_id = p.handbook_id
            JOIN pet_feature_skills f ON f.pet_id = p.pet_id WHERE p.pet_id = ?
            """, [.text("pet_000007")])
        guard tables == required, views == ["pet_skill_sources", "pet_feature_skills"],
              integrity.count == 1, integrity[0].text("integrity_check") == "ok",
              try db.rows("PRAGMA foreign_key_check").isEmpty, probe.count == 1,
              probe[0].text("dex_no") == "004", probe[0].text("skill_id") == "skill_000003" else {
            throw HandbookError("database_contract", "The Catalog failed its schema, integrity, or identity checks.")
        }
    }
}
