import Foundation

public enum PetSort: String, CaseIterable, Sendable { case handbook, name, attack, magicAttack, speed }
public enum ShinyFilter: String, CaseIterable, Sendable { case any, hasShiny, noShiny }
public enum PetFormFilter: String, CaseIterable, Sendable { case main, regional, lord }
public enum SkillFilter: String, Sendable { case all, features, learnable }
public enum PetCatalogLayout: String, CaseIterable, Sendable { case threeColumn, grid, list }

public struct PetQuery: Equatable, Sendable {
    public var keyword = ""
    public var typeIDs: [String] = []
    public var stages: [Int] = []
    public var forms: [PetFormFilter] = []
    public var shiny: ShinyFilter = .any
    public var seasons: [String] = []
    public var eggGroupIDs: [Int] = []
    public var sort: PetSort = .handbook
    public var limit = 80
    public var offset = 0
    public init() {}
}
public struct SkillQuery: Equatable, Sendable {
    public var keyword = ""
    public var filter: SkillFilter = .learnable
    public var skillTypes: [String] = []
    public var tags: [String] = []
    public var typeIDs: [String] = []
    public var limit = 80
    public var offset = 0
    public init() {}
}
public struct CatalogType: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
}
public struct EggGroup: Identifiable, Sendable {
    public let id: Int
    public let memberCount: Int
}
public struct PetSummary: Identifiable, Hashable, Sendable {
    public let id: String
    public let handbookID: String
    public let dexNo: String
    public let name: String
    public let title: String
    public let form: String?
    public let types: [String]
    public let illustrationKey: String?
    public let isDefaultForm: Bool
    public let stage: Int?
    public let hasShiny: Bool
    public let season: String?
    public let isLordEvolution: Bool
}
public struct BaseStat: Identifiable, Sendable {
    public let id: String
    public let value: Int?
}
public struct EggSize: Decodable, Sendable {
    public let minimum: Double?
    public let maximum: Double?
    public let miniMaximum: Double?
    public let hugeMinimum: Double?
    public let unit: String?
    enum CodingKeys: String, CodingKey {
        case minimum = "min", maximum = "max", miniMaximum = "mini_max", hugeMinimum = "huge_min", unit
    }
}
public struct PetDetail: Sendable {
    public let summary: PetSummary
    public let className: String?
    public let description: String?
    public let height: String?
    public let weight: String?
    public let starlight: Int?
    public let reviewGold: Int?
    public let canDoubleRide: Bool?
    public let eggGroups: [Int]
    public let eggSize: EggSize?
    public let stats: [BaseStat]
    public let sources: [SourceReference]
    public var totalBaseStats: Int? {
        guard stats.count == 6, stats.allSatisfy({ $0.value != nil }) else { return nil }
        return stats.compactMap(\.value).reduce(0, +)
    }
}
public struct SkillSummary: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let category: String?
    public let damageClass: String?
    public let description: String?
    public let iconKey: String?
    public let element: String?
    public let energyValue: Double?
    public let energyText: String?
    public let powerValue: Double?
    public let powerText: String?
    public let isFeature: Bool
}
public struct SkillDetail: Sendable {
    public let summary: SkillSummary
    public let target: String?
    public let descriptionNoteIDs: [String]
    public let sources: [SourceReference]
}
public struct LearnableSkill: Identifiable, Sendable {
    public let skill: SkillSummary
    public let sourceKind: String
    public let ordinal: Int
    public let learnLevel: Int?
    public let sourceStage: Int?
    public let bloodRaw: String?
    public let requirement: String?
    public var id: String { "\(sourceKind):\(ordinal):\(skill.id)" }
}
public struct PetSkillBundle: Sendable {
    public let feature: SkillSummary?
    public let learned: [LearnableSkill]
}
public struct SkillUser: Identifiable, Sendable {
    public let pet: PetSummary
    public let relationship: String
    public let ordinal: Int
    public let learnLevel: Int?
    public let sourceStage: Int?
    public let bloodRaw: String?
    public let requirement: String?
    public var id: String { "\(pet.id):\(relationship):\(ordinal)" }
}
public struct EvolutionEdge: Identifiable, Sendable {
    public let groupID: String
    public let fromID: String
    public let toID: String
    public let method: String
    public let level: Int?
    public let condition: String?
    public let ordinal: Int
    public var id: String { "\(groupID):\(ordinal)" }
}
public struct EvolutionGraph: Sendable {
    public let nodes: [PetSummary]
    public let edges: [EvolutionEdge]
}
public struct SourceReference: Identifiable, Sendable {
    public let name: String
    public let revisionID: Int
    public let licenseID: String
    public let url: String
    public var id: String { "\(name):\(revisionID)" }
}
public struct CatalogInfo: Sendable {
    public let datasetID: String
    public let schemaVersion: Int
    public let dataVersion: Int
    public let snapshotID: String
    public let builtAt: String
    public let adapterVersion: String
    public let builderVersion: String
    public let coverage: [String: Bool]
    public let earliestRevision: String
    public let latestRevision: String
}
public enum UserObjectType: String, Sendable { case pet, skill, handbook }
public struct ObjectRef: Hashable, Sendable {
    public let datasetID: String
    public let type: UserObjectType
    public let objectID: String
    public let name: String
    public init(datasetID: String = "roco-world-zh-cn", type: UserObjectType, objectID: String, name: String) {
        self.datasetID = datasetID
        self.type = type
        self.objectID = objectID
        self.name = name
    }
}
public struct FavoriteItem: Identifiable, Sendable {
    public let object: ObjectRef
    public let createdAt: String
    public var id: String { "\(object.datasetID):\(object.type.rawValue):\(object.objectID)" }
}
public struct CollectionMark: Identifiable, Sendable {
    public let datasetID: String
    public let handbookID: String
    public let name: String
    public let updatedAt: String
    public var id: String { "\(datasetID):\(handbookID)" }
}
public struct PersonalNote: Identifiable, Sendable {
    public let id: String
    public let object: ObjectRef
    public let content: String
    public let createdAt: String
    public let updatedAt: String
}
