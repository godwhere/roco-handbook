import Foundation
import CSystem

enum CatalogArchive {
    static let limits = [
        "assets/catalog/bundled_catalog.json": 64 * 1024,
        "assets/catalog/catalog.db": 128 * 1024 * 1024,
        "assets/catalog/ATTRIBUTION.txt": 256 * 1024,
    ]
    static func decode(_ data: Data, candidate: CatalogUpdateCandidate) throws -> CatalogBundle {
        let files = try entries(data)
        let bundle = try CatalogBundle(manifest: files["assets/catalog/bundled_catalog.json"]!,
                                       database: files["assets/catalog/catalog.db"]!,
                                       attribution: files["assets/catalog/ATTRIBUTION.txt"]!)
        guard bundle.manifest.dataVersion == candidate.dataVersion, bundle.manifest.snapshotId == candidate.snapshotId,
              bundle.manifest.coverage == candidate.coverage else {
            throw HandbookError("archive_manifest", "The Catalog package does not match its signed manifest.")
        }
        return bundle
    }
    static func entries(_ data: Data) throws -> [String: Data] {
        let bytes = [UInt8](data)
        func word(_ offset: Int, _ length: Int = 2) throws -> Int {
            guard offset >= 0, offset <= bytes.count - length else { throw invalid() }
            return (0..<length).reduce(0) { $0 | (Int(bytes[offset + $1]) << (8 * $1)) }
        }
        func slice(_ start: Int, _ size: Int) throws -> Data {
            guard start >= 0, size >= 0, start <= bytes.count - size else { throw invalid() }
            return Data(bytes[start..<(start + size)])
        }
        guard bytes.count >= 22, bytes.count <= 128 * 1024 * 1024 else { throw invalid() }
        let end = bytes.count - 22
        guard try word(end, 4) == 0x06054b50, try word(end + 4) == 0, try word(end + 6) == 0,
              try word(end + 8) == 3, try word(end + 10) == 3, try word(end + 20) == 0 else { throw invalid() }
        let centralSize = try word(end + 12, 4)
        let centralStart = try word(end + 16, 4)
        guard centralStart + centralSize == end else { throw invalid() }
        var position = centralStart
        var result: [String: Data] = [:]
        var ranges: [Range<Int>] = []
        for _ in 0..<3 {
            guard try word(position, 4) == 0x02014b50, try word(position + 6) <= 20 else { throw invalid() }
            let flags = try word(position + 8)
            let method = try word(position + 10)
            let crc = try word(position + 16, 4)
            let compressed = try word(position + 20, 4)
            let expanded = try word(position + 24, 4)
            let nameSize = try word(position + 28)
            let extraSize = try word(position + 30)
            let commentSize = try word(position + 32)
            let attributes = try word(position + 38, 4)
            let local = try word(position + 42, 4)
            guard flags & ~0x0808 == 0, method == 0 || method == 8, compressed > 0,
                  compressed <= bytes.count, expanded > 0, extraSize == 0, commentSize == 0,
                  try word(position + 34) == 0, attributes & 0x10 == 0,
                  ((attributes >> 16) & 0o170000 == 0 || (attributes >> 16) & 0o170000 == 0o100000),
                  let name = String(data: try slice(position + 46, nameSize), encoding: .utf8),
                  let maximum = limits[name], expanded <= maximum, result[name] == nil else { throw invalid() }
            guard try word(local, 4) == 0x04034b50, try word(local + 4) <= 20,
                  try word(local + 6) == flags, try word(local + 8) == method,
                  try word(local + 26) == nameSize, try word(local + 28) == 0,
                  try slice(local + 30, nameSize) == Data(name.utf8) else { throw invalid() }
            let contentStart = local + 30 + nameSize
            let contentEnd = contentStart + compressed
            guard contentEnd <= centralStart else { throw invalid() }
            let compressedData = try slice(contentStart, compressed)
            let contents = method == 0 ? compressedData : try inflateRaw(compressedData, size: expanded)
            guard contents.count == expanded, Int(checksum(contents)) == crc else { throw invalid() }
            var localEnd = contentEnd
            if flags & 8 != 0 {
                guard try word(local + 14, 4) == 0 || word(local + 14, 4) == crc,
                      try word(local + 18, 4) == 0 || word(local + 18, 4) == compressed,
                      try word(local + 22, 4) == 0 || word(local + 22, 4) == expanded else { throw invalid() }
                if try word(localEnd, 4) == 0x08074b50 { localEnd += 4 }
                guard try word(localEnd, 4) == crc, try word(localEnd + 4, 4) == compressed,
                      try word(localEnd + 8, 4) == expanded else { throw invalid() }
                localEnd += 12
            } else {
                guard try word(local + 14, 4) == crc, try word(local + 18, 4) == compressed,
                      try word(local + 22, 4) == expanded else { throw invalid() }
            }
            guard localEnd <= centralStart else { throw invalid() }
            ranges.append(local..<localEnd)
            result[name] = contents
            position += 46 + nameSize
        }
        ranges.sort { $0.lowerBound < $1.lowerBound }
        guard position == end, Set(result.keys) == Set(limits.keys), ranges[0].lowerBound == 0,
              ranges[0].upperBound == ranges[1].lowerBound, ranges[1].upperBound == ranges[2].lowerBound,
              ranges[2].upperBound == centralStart else { throw invalid() }
        return result
    }
    private static func checksum(_ data: Data) -> UInt32 {
        data.withUnsafeBytes { buffer in
            UInt32(crc32(0, buffer.bindMemory(to: Bytef.self).baseAddress, uInt(buffer.count)))
        }
    }
    private static func inflateRaw(_ data: Data, size: Int) throws -> Data {
        var output = Data(count: size)
        var stream = z_stream()
        guard inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else { throw invalid() }
        defer { inflateEnd(&stream) }
        let code = output.withUnsafeMutableBytes { destination in
            data.withUnsafeBytes { source in
                stream.next_in = UnsafeMutablePointer(mutating: source.bindMemory(to: Bytef.self).baseAddress)
                stream.avail_in = uInt(source.count)
                stream.next_out = destination.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(destination.count)
                return inflate(&stream, Z_FINISH)
            }
        }
        guard code == Z_STREAM_END, stream.total_out == size, stream.avail_in == 0 else { throw invalid() }
        return output
    }
    private static func invalid() -> HandbookError {
        HandbookError("archive_contract", "The complete Catalog ZIP failed its path, size, format, or integrity checks.")
    }
}
