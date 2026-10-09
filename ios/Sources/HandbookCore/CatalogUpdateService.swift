import Foundation
import CryptoKit

public struct CatalogUpdateCandidate: Sendable {
    public let dataVersion: Int
    public let releaseSequence: Int
    public let snapshotId: String
    public let coverage: [String: Bool]
    public let packageURL: URL
    public let archiveBytes: Int
    public let archiveHash: String
    let envelope: Data
}
public enum CatalogUpdateProgress: Sendable {
    case downloading(received: Int, total: Int)
    case verifying
}

enum CatalogSignature {
    static func base64url(_ text: String, count: Int? = nil, maximum: Int = 64 * 1024) throws -> Data {
        guard !text.isEmpty, text.count <= maximum * 2,
              text.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil else {
            throw HandbookError("base64url", "The signed Catalog encoding is invalid.")
        }
        let base = text.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: base + String(repeating: "=", count: (4 - base.count % 4) % 4)),
              data.count <= maximum, count == nil || data.count == count,
              encode(data) == text else { throw HandbookError("base64url", "The signed Catalog encoding is not canonical.") }
        return data
    }
    static func encode(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    static func canonical(_ value: Any) throws -> String {
        if let map = value as? [String: Any] {
            return try "{" + map.keys.sorted().map { key in
                try canonical(key) + ":" + canonical(map[key]!)
            }.joined(separator: ",") + "}"
        }
        if let array = value as? [Any] { return try "[" + array.map(canonical).joined(separator: ",") + "]" }
        if value is NSNull { return "null" }
        if let string = value as? String {
            return String(decoding: try JSONSerialization.data(withJSONObject: string, options: [.fragmentsAllowed, .withoutEscapingSlashes]), as: UTF8.self)
        }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() { return number.boolValue ? "true" : "false" }
            guard let integer = jsonInt(number), abs(Double(integer)) <= 9_007_199_254_740_991 else {
                throw HandbookError("canonical_number", "The signed Catalog numeric value is invalid.")
            }
            return String(integer)
        }
        throw HandbookError("canonical_json", "The signed Catalog JSON value is unsupported.")
    }
    static func verify(_ envelopeData: Data, trustData: Data, appVersion: String, currentDataVersion: Int,
                       highestSequence: Int, packagePolicy: ((URL) -> Bool)? = nil) throws -> CatalogUpdateCandidate {
        let envelope = try strictObject(envelopeData, fields: [
            "envelope_version", "key_id", "payload", "payload_encoding", "signature", "signature_algorithm",
        ])
        guard jsonInt(envelope["envelope_version"]) == 1, envelope["payload_encoding"] as? String == "base64url",
              envelope["signature_algorithm"] as? String == "ed25519", let keyID = envelope["key_id"] as? String,
              keyID.range(of: "^[a-z0-9][a-z0-9._-]{0,63}$", options: .regularExpression) != nil,
              let payloadText = envelope["payload"] as? String, let signatureText = envelope["signature"] as? String else {
            throw HandbookError("envelope_contract", "The signed Catalog envelope is invalid.")
        }
        let trust = try strictObject(trustData, fields: ["trust_store_version", "keys"])
        guard jsonInt(trust["trust_store_version"]) == 1, let keys = trust["keys"] as? [[String: Any]],
              !keys.isEmpty, Set(keys.compactMap { $0["key_id"] as? String }).count == keys.count else {
            throw HandbookError("trust_store", "The Catalog signing trust configuration is invalid.")
        }
        let keyFields: Set<String> = ["algorithm", "first_release_sequence", "key_id", "last_release_sequence", "public_key"]
        guard keys.allSatisfy({ Set($0.keys) == keyFields }), let key = keys.first(where: { $0["key_id"] as? String == keyID }),
              key["algorithm"] as? String == "ed25519", let keyText = key["public_key"] as? String,
              let first = jsonInt(key["first_release_sequence"]), first > 0 else {
            throw HandbookError("unknown_key", "This Catalog signing key is not trusted.")
        }
        let payload = try base64url(payloadText)
        let signature = try base64url(signatureText, count: 64)
        let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: base64url(keyText, count: 32))
        guard publicKey.isValidSignature(signature, for: payload) else {
            throw HandbookError("signature_invalid", "The Catalog update signature is invalid.")
        }
        let raw = try strictObject(payload, fields: [
            "catalog_schema_version", "coverage", "data_version", "dataset_id", "minimum_app_version",
            "minimum_protocol_version", "package", "protocol_version", "published_at_utc", "release_sequence", "snapshot_id",
        ], maximum: 64 * 1024)
        guard Data(try canonical(raw).utf8) == payload else {
            throw HandbookError("payload_canonical", "The signed Catalog payload is not canonical JSON.")
        }
        guard jsonInt(raw["protocol_version"]) == 1, jsonInt(raw["minimum_protocol_version"]) == 1,
              jsonInt(raw["catalog_schema_version"]) == 1, raw["dataset_id"] as? String == "roco-world-zh-cn",
              let version = jsonInt(raw["data_version"]), version > currentDataVersion,
              let sequence = jsonInt(raw["release_sequence"]), sequence > highestSequence, sequence >= first,
              let minimum = raw["minimum_app_version"] as? String, compatibleVersion(appVersion, minimum: minimum),
              let published = raw["published_at_utc"] as? String, published.hasSuffix("Z"), parseDate(published) != nil,
              let snapshot = raw["snapshot_id"] as? String,
              snapshot.range(of: "^snapshot-[0-9a-z-]{8,80}$", options: .regularExpression) != nil else {
            throw HandbookError("update_compatibility", "The Catalog release is stale, replayed, or incompatible with this App.")
        }
        if !(key["last_release_sequence"] is NSNull) {
            guard let last = jsonInt(key["last_release_sequence"]), last >= first, sequence <= last else {
                throw HandbookError("key_sequence", "The signing key is invalid for this release.")
            }
        }
        guard let package = raw["package"] as? [String: Any],
              Set(package.keys) == ["archive_bytes", "archive_format", "archive_sha256", "kind", "url"],
              package["archive_format"] as? String == "zip", package["kind"] as? String == "complete_catalog",
              let size = jsonInt(package["archive_bytes"]), size > 0, size <= 128 * 1024 * 1024,
              let hash = package["archive_sha256"] as? String, validHash(hash),
              let urlText = package["url"] as? String, let url = URL(string: urlText),
              packagePolicy?(url) ?? (CatalogTransport.allowedInitialURL(url) &&
                  url.absoluteString == "https://github.com/godwhere/roco-handbook/releases/download/catalog-data-v\(version)/catalog-v\(version).zip") else {
            throw HandbookError("package_contract", "The Catalog package is invalid or uses an unsupported host.")
        }
        return CatalogUpdateCandidate(dataVersion: version, releaseSequence: sequence, snapshotId: snapshot,
                                      coverage: try CatalogManifest.validateCoverage(raw["coverage"]),
                                      packageURL: url, archiveBytes: size, archiveHash: hash, envelope: envelopeData)
    }
    private static func compatibleVersion(_ current: String, minimum: String) -> Bool {
        func components(_ value: String) -> [Int]? {
            guard value.range(of: "^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$", options: .regularExpression) != nil else { return nil }
            let parts = value.split(separator: ".").compactMap { Int($0) }
            return parts.count == 3 ? parts : nil
        }
        guard let a = components(current), let b = components(minimum) else { return false }
        return a == b || b.lexicographicallyPrecedes(a)
    }
}

// The only native runtime network boundary. Each request is explicitly initiated in Settings.
final class CatalogTransport: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    static let discovery = URL(string: "https://github.com/godwhere/roco-handbook/releases/download/catalog-channel/catalog-manifest.json")!
    static func allowedInitialURL(_ url: URL) -> Bool {
        url.scheme == "https" && url.host == "github.com" && (url.port == nil || url.port == 443) &&
            url.user == nil && url.password == nil && url.fragment == nil && url.query == nil &&
            url.path.hasPrefix("/godwhere/roco-handbook/releases/download/") &&
            !url.path.contains("..") && !url.path.contains("\\")
    }
    static func allowedRedirect(_ url: URL) -> Bool {
        url.scheme == "https" && url.host == "release-assets.githubusercontent.com" && (url.port == nil || url.port == 443) &&
            url.user == nil && url.password == nil && url.fragment == nil &&
            url.path.hasPrefix("/github-production-release-asset/") && !url.path.contains("..")
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
    func fetch(_ url: URL, maximum: Int, expected: Int? = nil, discovery: Bool = false,
               progress: (@Sendable (Int) async -> Void)? = nil) async throws -> Data? {
        guard Self.allowedInitialURL(url) else { throw HandbookError("update_url", "The Catalog update URL is not allowed.") }
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = nil; config.httpShouldSetCookies = false
        config.urlCredentialStorage = nil; config.urlCache = nil
        config.timeoutIntervalForRequest = 30; config.timeoutIntervalForResource = 120
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        var destination = url
        for attempt in 0...1 {
            try Task.checkCancellation()
            var request = URLRequest(url: destination, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
            request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
            request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
            let (stream, response) = try await session.bytes(for: request)
            guard let response = response as? HTTPURLResponse else { throw HandbookError("update_http", "The Catalog server response is invalid.") }
            if response.statusCode == 302 {
                guard attempt == 0, let location = response.value(forHTTPHeaderField: "Location"),
                      let next = URL(string: location), Self.allowedRedirect(next) else {
                    throw HandbookError("update_redirect", "The Catalog redirect is not allowed.")
                }
                destination = next; continue
            }
            if discovery, response.statusCode == 404 { return nil }
            guard response.statusCode == 200, response.expectedContentLength <= maximum,
                  expected == nil || response.expectedContentLength < 0 || response.expectedContentLength == Int64(expected!) else {
                throw HandbookError("update_http", "The Catalog download failed or exceeds its size limit.")
            }
            if let encoding = response.value(forHTTPHeaderField: "Content-Encoding"), encoding.lowercased() != "identity" {
                throw HandbookError("update_encoding", "The Catalog response encoding is unsupported.")
            }
            var result = Data()
            for try await byte in stream {
                result.append(byte)
                guard result.count <= maximum else { throw HandbookError("update_size", "The Catalog download exceeds its size limit.") }
                if result.count % 16384 == 0 {
                    try Task.checkCancellation()
                    await progress?(result.count)
                }
            }
            guard !result.isEmpty, expected == nil || result.count == expected else {
                throw HandbookError("update_size", "The Catalog download is incomplete.")
            }
            await progress?(result.count)
            return result
        }
        throw HandbookError("update_redirect", "The Catalog exceeded its redirect limit.")
    }
}

public actor CatalogUpdateService {
    private let trustData: Data
    private let installer: CatalogInstaller
    private let appVersion: String
    public init(trustData: Data, installer: CatalogInstaller, appVersion: String) {
        self.trustData = trustData; self.installer = installer; self.appVersion = appVersion
    }
    public func check(currentDataVersion: Int) async throws -> CatalogUpdateCandidate? {
        guard let data = try await CatalogTransport().fetch(CatalogTransport.discovery, maximum: 128 * 1024, discovery: true) else { return nil }
        let floor = try await installer.highestSequence()
        // Verify signatures before interpreting an already-installed discovery result.
        let verified = try CatalogSignature.verify(data, trustData: trustData, appVersion: appVersion,
                                                   currentDataVersion: 0, highestSequence: 0)
        if verified.dataVersion <= currentDataVersion && verified.releaseSequence <= floor { return nil }
        return try CatalogSignature.verify(data, trustData: trustData, appVersion: appVersion,
                                           currentDataVersion: currentDataVersion, highestSequence: floor)
    }
    public func install(_ candidate: CatalogUpdateCandidate, currentDataVersion: Int,
                        progress: @escaping @Sendable (CatalogUpdateProgress) async -> Void) async throws -> CatalogOpenResult {
        let floor = try await installer.highestSequence()
        let verified = try CatalogSignature.verify(candidate.envelope, trustData: trustData, appVersion: appVersion,
                                                    currentDataVersion: currentDataVersion, highestSequence: floor)
        await progress(.downloading(received: 0, total: verified.archiveBytes))
        guard let bytes = try await CatalogTransport().fetch(verified.packageURL, maximum: verified.archiveBytes, expected: verified.archiveBytes,
                                                             progress: { received in await progress(.downloading(received: received, total: verified.archiveBytes)) }),
              sha256(bytes) == verified.archiveHash else {
            throw HandbookError("archive_hash", "The Catalog download does not match its signed hash.")
        }
        try Task.checkCancellation()
        await progress(.verifying)
        let bundle = try CatalogArchive.decode(bytes, candidate: verified)
        return try await installer.installRemote(bundle, sequence: verified.releaseSequence)
    }
}
