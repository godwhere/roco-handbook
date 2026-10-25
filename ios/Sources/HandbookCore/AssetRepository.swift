import Foundation

public struct GameDescription: Decodable, Identifiable, Sendable {
    public let noteId: String
    public let name: String
    public let description: String
    public let category: String
    public var id: String { noteId }
}
public struct DescriptionCatalog: Decodable, Sendable {
    let contractVersion: Int
    let datasetId: String
    public let categoryOrder: [String]
    public let categoryLabels: [String: String]
    public let entries: [GameDescription]
}
public struct ActivityEntry: Decodable, Identifiable, Sendable {
    public let activityId: String
    public let seriesId: String
    public let name: String
    public let summary: String?
    public let description: String?
    public let category: String
    public let kindLabel: String
    public let pageTitle: String?
    public let masked: Bool
    public let startAt: String?
    public let endAt: String?
    public let iconPath: String?
    public var id: String { activityId }
    public var startDate: Date? { startAt.flatMap(parseDate) }
    public var endDate: Date? { endAt.flatMap(parseDate) }
    public func status(at date: Date = Date()) -> String {
        if let startDate, date < startDate { return "Upcoming" }
        if let endDate, date > endDate { return "Ended" }
        if startDate != nil || endDate != nil { return "Active" }
        return "Unknown"
    }
}
public struct ActivityCatalog: Decodable, Sendable {
    let contractVersion: Int
    let datasetId: String
    public let categoryOrder: [String]
    public let categoryLabels: [String: String]
    public let entries: [ActivityEntry]
}
public struct FashionVariant: Decodable, Identifiable, Sendable {
    public let gender: String
    public let genderLabel: String
    public let name: String
    public let description: String?
    public let acquisition: [String]
    public let itemCount: Int
    public let imagePath: String
    public var id: String { gender }
}
public struct FashionEntry: Decodable, Identifiable, Sendable {
    public let outfitId: String
    public let name: String
    public let pageTitle: String
    public let description: String?
    public let gradeName: String
    public let quality: Int
    public let seriesId: Int
    public let variants: [FashionVariant]
    public var id: String { outfitId }
}
public struct FashionCatalog: Decodable, Sendable {
    let contractVersion: Int
    let datasetId: String
    public let genderOrder: [String]
    public let entries: [FashionEntry]
}
public struct TypeRelation: Decodable, Identifiable, Sendable {
    public let strongAgainst: [String]
    public let resistedBy: [String]
    public let name: String
    public var id: String { name }
    enum CodingKeys: String, CodingKey { case strongAgainst, resistedBy }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        strongAgainst = try values.decode([String].self, forKey: .strongAgainst)
        resistedBy = try values.decode([String].self, forKey: .resistedBy)
        name = decoder.codingPath.last?.stringValue ?? ""
    }
}
public struct IncomingDamage: Identifiable, Sendable {
    public let type: String
    public let multiplier: Double
    public var id: String { type }
}
public struct TypeRelationships: Sendable {
    public let outgoing: [TypeRelation]
    public let incoming: [IncomingDamage]
}
public struct AttackCoverage: Sendable {
    public let availableTypes: [String]
    public let selectedTypes: [String]
    public let covered: [String]
    public let resisted: [String]
    public let neutral: [String]
    public let source: VisualSource
}
public struct VisualSource: Identifiable, Sendable {
    public let name: String
    public let url: String
    public let frozenAt: String?
    public var id: String { url }
}
private struct TypeContract: Decodable {
    let contractVersion: Int
    let datasetId: String
    let typeOrder: [String]
    let relations: [String: TypeRelation]
    let source: TypeSource?
    enum CodingKeys: String, CodingKey { case contractVersion, datasetId, typeOrder, relations, source }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        contractVersion = try values.decode(Int.self, forKey: .contractVersion)
        datasetId = try values.decode(String.self, forKey: .datasetId)
        typeOrder = try values.decode([String].self, forKey: .typeOrder)
        relations = try values.decode([String: TypeRelation].self, forKey: .relations)
        source = try? values.decode(TypeSource.self, forKey: .source)
    }
}
private struct TypeSource: Decodable {
    let pageId: Int
    let revisionId: Int
    let title: String
    let revisedAtUtc: String
    let sourceSha1: String
    let sourceUrl: String
}
func parseDate(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
}

public actor AssetRepository {
    public let assetRoot: URL
    public init(assetRoot: URL) { self.assetRoot = assetRoot }
    private func decode<T: Decodable>(_ type: T.Type, _ path: String) throws -> T {
        let url = assetRoot.appendingPathComponent(path)
        try FileSafety.regular(url)
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size > 0, size <= 8 * 1024 * 1024 else {
            throw HandbookError("asset_size", "The offline reference asset has an invalid size.")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: Data(contentsOf: url))
    }
    private func validate(version: Int, dataset: String, ids: [String], categories: [String] = [], labels: [String: String] = [:]) throws {
        guard version == 1, dataset == "roco-world-zh-cn", !ids.isEmpty,
              ids.allSatisfy({ !$0.isEmpty }), Set(ids).count == ids.count,
              Set(categories).count == categories.count, Set(categories) == Set(labels.keys),
              labels.values.allSatisfy({ !$0.isEmpty }) else {
            throw HandbookError("asset_contract", "The offline reference asset has an invalid identity or shape.")
        }
    }
    public func descriptions() throws -> DescriptionCatalog {
        let result = try decode(DescriptionCatalog.self, "wiki/game-descriptions-v1.json")
        try validate(version: result.contractVersion, dataset: result.datasetId, ids: result.entries.map(\.id),
                     categories: result.categoryOrder, labels: result.categoryLabels)
        guard result.entries.allSatisfy({ result.categoryOrder.contains($0.category) && !$0.name.isEmpty && !$0.description.isEmpty }) else {
            throw HandbookError("description_contract", "An offline description is invalid.")
        }
        return result
    }
    public func visualSources() throws -> [VisualSource] {
        struct FontEntry: Decodable { let family: String; let sourceUrl: String }
        struct FontManifest: Decodable {
            let manifestVersion: Int; let datasetId: String
            let fonts: [FontEntry]; let importedAtUtc: String
        }
        struct ImageEntry: Decodable { let sourceTitle: String; let sourceUrl: String; let sourceTimestamp: String }
        struct ImageManifest: Decodable {
            let manifestVersion: Int; let datasetId: String; let assets: [ImageEntry]
        }
        let fonts = try decode(FontManifest.self, "fonts/v1/font-manifest.json")
        guard fonts.manifestVersion == 1, fonts.datasetId == "roco-world-zh-cn", !fonts.fonts.isEmpty else {
            throw HandbookError("font_sources", "The frozen font sources are invalid.")
        }
        var result = fonts.fonts.map { VisualSource(name: $0.family, url: $0.sourceUrl, frozenAt: fonts.importedAtUtc) }
        for path in ["wiki/v4/asset-manifest.json", "wiki/tools/v2/asset-manifest.json", "wiki/references/v1/asset-manifest.json"] {
            let images = try decode(ImageManifest.self, path)
            guard images.manifestVersion == 1, images.datasetId == "roco-world-zh-cn", !images.assets.isEmpty else {
                throw HandbookError("image_sources", "The frozen image sources are invalid.")
            }
            result += images.assets.map { VisualSource(name: $0.sourceTitle, url: $0.sourceUrl, frozenAt: $0.sourceTimestamp) }
        }
        var seen = Set<String>()
        return result.filter { seen.insert($0.url).inserted }
    }
    public func activities() throws -> ActivityCatalog {
        let result = try decode(ActivityCatalog.self, "wiki/activity-timeline-v1.json")
        try validate(version: result.contractVersion, dataset: result.datasetId, ids: result.entries.map(\.id),
                     categories: result.categoryOrder, labels: result.categoryLabels)
        for entry in result.entries {
            guard !entry.name.isEmpty, !entry.seriesId.isEmpty, result.categoryOrder.contains(entry.category),
                  entry.startAt == nil || entry.startDate != nil, entry.endAt == nil || entry.endDate != nil else {
                throw HandbookError("activity_contract", "An offline activity has an invalid identity or date.")
            }
            if let path = entry.iconPath { _ = try Self.toolImage(path, prefix: "activities/icons/") }
        }
        return result
    }
    public func fashions() throws -> FashionCatalog {
        let result = try decode(FashionCatalog.self, "wiki/fashion-catalog-v1.json")
        try validate(version: result.contractVersion, dataset: result.datasetId, ids: result.entries.map(\.id))
        guard Set(result.genderOrder) == ["male", "female"], result.genderOrder.count == 2 else {
            throw HandbookError("fashion_genders", "The offline fashion genders are invalid.")
        }
        for entry in result.entries {
            guard !entry.name.isEmpty, !entry.variants.isEmpty,
                  Set(entry.variants.map(\.gender)) == Set(result.genderOrder), entry.variants.count == 2 else {
                throw HandbookError("fashion_contract", "An offline outfit has invalid variants.")
            }
            for variant in entry.variants { _ = try Self.toolImage(variant.imagePath, prefix: "fashions/cards/") }
        }
        return result
    }
    public func referenceCatalog(_ kind: ReferenceCatalogKind) throws -> ReferenceCatalog {
        let result: ReferenceCatalog
        do {
            result = try decode(ReferenceCatalog.self, "wiki/references/v1/\(kind.rawValue).json")
        } catch {
            throw HandbookError("reference_contract", "The offline reference catalog is invalid.")
        }
        try result.validate(for: kind)
        return result
    }
    public func attackCoverage(for types: [String]) throws -> AttackCoverage {
        let contract = try decode(TypeContract.self, "wiki/type-relations-v1.json")
        let names = types.map { $0.hasSuffix("\u{7cfb}") ? String($0.dropLast()) : $0 }
        let placeholder = "\u{65e0}\u{7cfb}\u{522b}"
        let order = contract.typeOrder.filter { $0 != placeholder }
        let allowed = Set(contract.typeOrder)
        let expected = Set(CatalogAssets.typeFiles.keys)
        guard contract.contractVersion == 1, contract.datasetId == "roco-world-zh-cn",
              Set(order) == expected, allowed == expected.union([placeholder]),
              allowed.count == contract.typeOrder.count, allowed == Set(contract.relations.keys),
              names.count <= 5, Set(names).count == names.count, Set(names).isSubset(of: Set(order)),
              contract.relations.values.allSatisfy({ relation in
                  let strong = Set(relation.strongAgainst), resisted = Set(relation.resistedBy)
                  return strong.count == relation.strongAgainst.count && resisted.count == relation.resistedBy.count &&
                      strong.union(resisted).isSubset(of: allowed) && strong.isDisjoint(with: resisted)
              }) else {
            throw HandbookError("type_contract", "The offline attack coverage types or relationships are invalid.")
        }
        guard let source = contract.source, source.pageId == 12987, source.revisionId > 0,
              source.title == "Module:TypeRelation", parseDate(source.revisedAtUtc) != nil,
              source.sourceSha1.utf8.count == 40,
              source.sourceSha1.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }),
              let url = URLComponents(string: source.sourceUrl), url.url != nil,
              url.scheme == "https", url.host == "wiki.biligame.com", url.path == "/rocom/index.php",
              url.port == nil || url.port == 443, url.user == nil, url.password == nil, url.fragment == nil,
              let query = url.queryItems, query.count == 2,
              query.first(where: { $0.name == "title" })?.value == source.title,
              query.first(where: { $0.name == "oldid" })?.value == String(source.revisionId) else {
            throw HandbookError("type_contract", "The offline attack coverage source is invalid.")
        }
        let visualSource = VisualSource(name: source.title, url: source.sourceUrl, frozenAt: source.revisedAtUtc)
        let selected = order.filter { names.contains($0) }
        guard !selected.isEmpty else {
            return AttackCoverage(availableTypes: order, selectedTypes: [], covered: [], resisted: [], neutral: [], source: visualSource)
        }
        let relations = selected.compactMap { contract.relations[$0] }
        let covered = Set(relations.flatMap(\.strongAgainst))
        let resisted = relations.reduce(Set(order)) { $0.intersection($1.resistedBy) }
        return AttackCoverage(availableTypes: order, selectedTypes: selected,
                              covered: order.filter { covered.contains($0) },
                              resisted: order.filter { resisted.contains($0) },
                              neutral: order.filter { !covered.contains($0) && !resisted.contains($0) }, source: visualSource)
    }
    public func relationships(for types: [String]) throws -> TypeRelationships {
        let contract = try decode(TypeContract.self, "wiki/type-relations-v1.json")
        let names = types.map { $0.hasSuffix("\u{7cfb}") ? String($0.dropLast()) : $0 }
        guard contract.contractVersion == 1, contract.datasetId == "roco-world-zh-cn",
              !names.isEmpty, names.count <= 2, Set(names).count == names.count,
              Set(contract.typeOrder) == Set(contract.relations.keys),
              Set(contract.typeOrder).count == contract.typeOrder.count,
              names.allSatisfy({ contract.relations[$0] != nil }),
              contract.relations.values.allSatisfy({
                  Set($0.strongAgainst + $0.resistedBy).isSubset(of: Set(contract.typeOrder))
              }) else {
            throw HandbookError("type_contract", "The offline type relationships are invalid.")
        }
        var incoming: [IncomingDamage] = []
        for attacker in contract.typeOrder where attacker != "\u{65e0}\u{7cfb}\u{522b}" {
            guard let attack = contract.relations[attacker] else { continue }
            var multiplier = 1.0
            for defender in names {
                if attack.strongAgainst.contains(defender) { multiplier *= 2 }
                else if attack.resistedBy.contains(defender) { multiplier *= 0.5 }
            }
            if names.count == 2, multiplier >= 4 { multiplier = 3 }
            if multiplier != 1 { incoming.append(IncomingDamage(type: attacker, multiplier: multiplier)) }
        }
        incoming.sort {
            $0.multiplier == $1.multiplier ?
                (contract.typeOrder.firstIndex(of: $0.type) ?? 0) < (contract.typeOrder.firstIndex(of: $1.type) ?? 0) :
                $0.multiplier > $1.multiplier
        }
        return TypeRelationships(outgoing: names.compactMap { contract.relations[$0] }, incoming: incoming)
    }
    public static func toolImage(_ path: String, prefix: String) throws -> String {
        guard path.hasPrefix(prefix), path.hasSuffix(".png"), !path.contains(".."),
              !path.contains("\\"), path.split(separator: "/").count == 3 else {
            throw HandbookError("asset_path", "The offline image path is invalid.")
        }
        return "wiki/tools/v2/\(path)"
    }
}

public enum CatalogAssets {
    public static func pet(_ key: String?, shiny: Bool = false) -> String? {
        guard let key, safeKey(key) else { return nil }
        return shiny ? "wiki/v4/pets/shiny/\(key)_yise.png" : "wiki/v4/pets/illustrations/\(key).png"
    }
    public static func skill(_ skill: SkillSummary) -> String? {
        guard let key = skill.iconKey, safeKey(key) else { return nil }
        return "wiki/v4/skills/\(skill.isFeature ? "Feature" : "Skill")_\(key).png"
    }
    public static func type(_ type: String) -> String? {
        let short = type.hasSuffix("\u{7cfb}") ? String(type.dropLast()) : type
        return typeFiles[short].map { "wiki/v4/ui/types/\($0).png" }
    }
    private static func safeKey(_ key: String) -> Bool {
        !key.isEmpty && !key.contains("/") && !key.contains("\\") && !key.contains("..") && !key.contains("\0")
    }
    static let typeFiles = [
        "\u{666e}\u{901a}": "normal", "\u{8349}": "grass", "\u{706b}": "fire", "\u{6c34}": "water",
        "\u{5149}": "light", "\u{5730}": "ground", "\u{51b0}": "ice", "\u{9f99}": "dragon",
        "\u{7535}": "electric", "\u{6bd2}": "poison", "\u{866b}": "bug", "\u{6b66}": "martial",
        "\u{7ffc}": "wing", "\u{840c}": "cute", "\u{5e7d}": "ghost", "\u{6076}": "evil",
        "\u{673a}\u{68b0}": "mechanical", "\u{5e7b}": "illusion",
    ]
}
