import XCTest
import CSystem
@testable import HandbookCore

final class CatalogUpdateTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
    }
    private func fixture(_ name: String) throws -> Data {
        try Data(contentsOf: root.appendingPathComponent("app/test/fixtures/catalog_update/\(name).json"))
    }
    func testExistingEd25519FixtureVerifiesWithoutNetwork() throws {
        let candidate = try CatalogSignature.verify(fixture("remote_catalog_envelope_v1"), trustData: fixture("catalog_trust_store_v1"),
                                                    appVersion: "1.2.0", currentDataVersion: 1, highestSequence: 0,
                                                    packagePolicy: { $0.host == "updates.example.test" })
        XCTAssertEqual(candidate.dataVersion, 2)
        XCTAssertEqual(candidate.releaseSequence, 2)
        XCTAssertEqual(candidate.snapshotId, "snapshot-phase7-fixture-v2")
    }
    func testInvalidSignatureReplayAndHostAreRejected() throws {
        let envelope = try fixture("remote_catalog_envelope_v1")
        let trust = try fixture("catalog_trust_store_v1")
        XCTAssertThrowsError(try CatalogSignature.verify(envelope, trustData: trust, appVersion: "1.2.0",
                                                         currentDataVersion: 1, highestSequence: 2, packagePolicy: { _ in true }))
        XCTAssertThrowsError(try CatalogSignature.verify(envelope, trustData: trust, appVersion: "0.9.0",
                                                         currentDataVersion: 1, highestSequence: 0, packagePolicy: { _ in true }))
        XCTAssertThrowsError(try CatalogSignature.verify(envelope, trustData: trust, appVersion: "1.2.0",
                                                         currentDataVersion: 1, highestSequence: 0))
        var altered = try JSONSerialization.jsonObject(with: envelope) as! [String: Any]
        altered["signature"] = CatalogSignature.encode(Data(repeating: 0, count: 64))
        XCTAssertThrowsError(try CatalogSignature.verify(JSONSerialization.data(withJSONObject: altered),
                                                         trustData: trust, appVersion: "1.2.0", currentDataVersion: 1,
                                                         highestSequence: 0, packagePolicy: { _ in true }))
        XCTAssertThrowsError(try CatalogSignature.base64url("YQ=="))
        XCTAssertThrowsError(try CatalogSignature.base64url("YR"))
    }
    func testTransportAllowsOnlyOwnedGitHubReleaseAndOneAssetHost() throws {
        XCTAssertTrue(CatalogTransport.allowedInitialURL(CatalogTransport.discovery))
        for url in ["http://github.com/godwhere/roco-handbook/releases/download/v1/a.zip",
                    "https://github.com/another/repository/releases/download/v1/a.zip",
                    "https://user@github.com/godwhere/roco-handbook/releases/download/v1/a.zip",
                    "https://github.com/godwhere/roco-handbook/releases/download/v1/a.zip?token=secret"] {
            XCTAssertFalse(CatalogTransport.allowedInitialURL(URL(string: url)!))
        }
        XCTAssertTrue(CatalogTransport.allowedRedirect(URL(string: "https://release-assets.githubusercontent.com/github-production-release-asset/123/file?signature=temporary")!))
        XCTAssertFalse(CatalogTransport.allowedRedirect(URL(string: "https://example.test/github-production-release-asset/123/file")!))
    }
    func testStoredAndDeflatedZipValidateExactEntriesAndCRCs() throws {
        let files = [
            ("assets/catalog/bundled_catalog.json", Data("{\"manifest_version\":1}".utf8)),
            ("assets/catalog/catalog.db", Data(repeating: 42, count: 4096)),
            ("assets/catalog/ATTRIBUTION.txt", Data("Owned offline archive fixture".utf8)),
        ]
        for compressed in [false, true] {
            let bytes = try zip(files, compressed: compressed)
            let decoded = try CatalogArchive.entries(bytes)
            for (path, expected) in files { XCTAssertEqual(decoded[path], expected) }
            var damaged = bytes
            damaged[45] ^= 1
            XCTAssertThrowsError(try CatalogArchive.entries(damaged))
            XCTAssertThrowsError(try CatalogArchive.entries(bytes + Data([0])))
        }
        let traversal = [("../catalog.db", Data([1]))] + Array(files.dropFirst())
        XCTAssertThrowsError(try CatalogArchive.entries(zip(traversal)))
        XCTAssertThrowsError(try CatalogArchive.entries(zip(files + [("unexpected.txt", Data([1]))])))
    }
    private func zip(_ files: [(String, Data)], compressed: Bool = false) throws -> Data {
        var local = Data(); var central = Data()
        func append(_ value: Int, bytes: Int, to data: inout Data) {
            for index in 0..<bytes { data.append(UInt8(truncatingIfNeeded: value >> (8 * index))) }
        }
        for (name, contents) in files {
            let encodedName = Data(name.utf8)
            let payload = compressed ? try deflate(contents) : contents
            let checksum = contents.withUnsafeBytes { Int(crc32(0, $0.bindMemory(to: Bytef.self).baseAddress, uInt($0.count))) }
            let offset = local.count
            append(0x04034b50, bytes: 4, to: &local)
            for value in [20, 0, compressed ? 8 : 0, 0, 0] { append(value, bytes: 2, to: &local) }
            for value in [checksum, payload.count, contents.count] { append(value, bytes: 4, to: &local) }
            append(encodedName.count, bytes: 2, to: &local); append(0, bytes: 2, to: &local)
            local += encodedName; local += payload
            append(0x02014b50, bytes: 4, to: &central)
            for value in [20, 20, 0, compressed ? 8 : 0, 0, 0] { append(value, bytes: 2, to: &central) }
            for value in [checksum, payload.count, contents.count] { append(value, bytes: 4, to: &central) }
            for value in [encodedName.count, 0, 0, 0, 0] { append(value, bytes: 2, to: &central) }
            append(0, bytes: 4, to: &central); append(offset, bytes: 4, to: &central); central += encodedName
        }
        let centralOffset = local.count
        local += central
        append(0x06054b50, bytes: 4, to: &local)
        for value in [0, 0, files.count, files.count] { append(value, bytes: 2, to: &local) }
        append(central.count, bytes: 4, to: &local); append(centralOffset, bytes: 4, to: &local); append(0, bytes: 2, to: &local)
        return local
    }
    private func deflate(_ data: Data) throws -> Data {
        var stream = z_stream()
        XCTAssertEqual(deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -MAX_WBITS, 8, Z_DEFAULT_STRATEGY,
                                    ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)), Z_OK)
        defer { deflateEnd(&stream) }
        var output = Data(count: data.count + 100)
        let code = output.withUnsafeMutableBytes { destination in
            data.withUnsafeBytes { source in
                stream.next_in = UnsafeMutablePointer(mutating: source.bindMemory(to: Bytef.self).baseAddress)
                stream.avail_in = uInt(source.count)
                stream.next_out = destination.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(destination.count)
                return CSystem.deflate(&stream, Z_FINISH)
            }
        }
        XCTAssertEqual(code, Z_STREAM_END)
        return output.prefix(Int(stream.total_out))
    }
}
