import Foundation

public enum ReferenceCatalogKind: String, CaseIterable, Hashable, Sendable, Decodable {
    case items, research, medals, trials, habitats

    public var supportsProgress: Bool { self == .research || self == .trials }

    func acceptsID(_ id: String) -> Bool {
        let pattern: String
        switch self {
        case .items: pattern = "item_[0-9a-f]{12}"
        case .research: pattern = "pt_[0-9]{6}_[0-9]{6}"
        case .medals: pattern = "medal_[0-9]+"
        case .trials: pattern = "gt_[0-9a-f]{16}"
        case .habitats: pattern = "p-[0-9a-f]{16}"
        }
        return referenceID(id, pattern: pattern)
    }
}

public struct ReferenceSource: Decodable, Identifiable, Sendable {
    public let title: String
    public let pageId: Int
    public let revisionId: Int
    public let revisedAtUtc: String
    public let sha1: String
    public let sha256: String
    public let url: String
    public var id: String { "\(pageId):\(revisionId)" }
}

public struct ReferenceGroup: Decodable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let imagePath: String?
}

public struct ReferenceSection: Decodable, Sendable {
    public let title: String
    public let lines: [String]
}

public struct ReferenceLink: Decodable, Identifiable, Sendable {
    public let kind: String
    public let id: String
    public let name: String
}

public struct ReferenceEntry: Decodable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let groupId: String
    public let visible: Bool
    public let sections: [ReferenceSection]
    public let links: [ReferenceLink]
    public let subtitle: String?
    public let description: String?
    public let imagePath: String?
    public let handbookId: String?
    public let progressId: String?
}

public struct ReferenceCatalog: Decodable, Sendable {
    public let contractVersion: Int
    public let datasetId: String
    public let snapshotId: String
    public let kind: ReferenceCatalogKind
    public let sources: [ReferenceSource]
    public let groups: [ReferenceGroup]
    public let entries: [ReferenceEntry]
    public var visibleEntries: [ReferenceEntry] { entries.filter(\.visible) }

    func validate(for expectedKind: ReferenceCatalogKind) throws {
        let groupIDs = Set(groups.map(\.id))
        guard contractVersion == 1, datasetId == "roco-world-zh-cn", kind == expectedKind,
              referenceText(snapshotId), !sources.isEmpty, !groups.isEmpty, !entries.isEmpty,
              Set(sources.map(\.pageId)).count == sources.count,
              Set(sources.map(\.title)).count == sources.count,
              sources.allSatisfy(validReferenceSource), groupIDs.count == groups.count,
              groups.allSatisfy({ referenceText($0.id) && referenceText($0.title) && validReferenceImage($0.imagePath) }),
              Set(entries.map(\.id)).count == entries.count,
              entries.allSatisfy({ entry in
                  guard kind.acceptsID(entry.id), referenceText(entry.name), groupIDs.contains(entry.groupId),
                        validReferenceImage(entry.imagePath),
                        [entry.subtitle, entry.description].compactMap({ $0 }).allSatisfy({ !$0.contains("\0") }),
                        entry.handbookId.map({ referenceID($0, pattern: "handbook_[0-9]{6}") }) ?? true,
                        entry.sections.allSatisfy({ referenceText($0.title) && $0.lines.allSatisfy(referenceText) }),
                        entry.links.allSatisfy({ link in
                            referenceText(link.name) &&
                                ((link.kind == "pet" && referenceID(link.id, pattern: "pet_[0-9]{6}")) ||
                                 (link.kind == "item" && ReferenceCatalogKind.items.acceptsID(link.id)))
                        }) else { return false }
                  switch kind {
                  case .research:
                      return entry.progressId == entry.id && entry.handbookId == entry.groupId
                  case .trials:
                      return entry.progressId == entry.id
                  case .items, .medals, .habitats:
                      return entry.progressId == nil
                  }
              }) else {
            throw HandbookError("reference_contract", "The offline reference catalog is invalid.")
        }
    }
}

private func referenceID(_ value: String, pattern: String) -> Bool {
    value.range(of: "\\A(?:\(pattern))\\z", options: .regularExpression) != nil
}

private func referenceText(_ value: String) -> Bool {
    !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !value.contains("\0")
}

private func validReferenceSource(_ source: ReferenceSource) -> Bool {
    guard referenceText(source.title), source.pageId > 0, source.revisionId > 0,
          parseDate(source.revisedAtUtc) != nil,
          referenceID(source.sha1, pattern: "[0-9a-f]{40}"), referenceID(source.sha256, pattern: "[0-9a-f]{64}"),
          let url = URLComponents(string: source.url), url.url != nil,
          url.scheme == "https", url.host == "wiki.biligame.com", url.path == "/nrc/index.php",
          url.port == nil || url.port == 443, url.user == nil, url.password == nil, url.fragment == nil,
          let query = url.queryItems, query.count == 2,
          query.first(where: { $0.name == "title" })?.value == source.title,
          query.first(where: { $0.name == "oldid" })?.value == String(source.revisionId) else { return false }
    return true
}

private func validReferenceImage(_ path: String?) -> Bool {
    guard let path else { return true }
    let components = path.split(separator: "/", omittingEmptySubsequences: false)
    guard path.hasSuffix(".png"), !path.contains("\\"), !path.contains(":"),
          path.utf8.allSatisfy({ $0 >= 32 && $0 != 127 }),
          components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else { return false }
    return (path.hasPrefix("wiki/references/v1/icons/") && components.count == 5) ||
        ((path.hasPrefix("wiki/v3/") || path.hasPrefix("wiki/v4/")) && components.count >= 4)
}
