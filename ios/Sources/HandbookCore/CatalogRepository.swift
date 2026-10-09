import Foundation

public actor CatalogRepository {
    public let databaseURL: URL
    public init(databaseURL: URL) { self.databaseURL = databaseURL }

    private func read<T>(_ operation: (SQLite) throws -> T) throws -> T {
        try FileSafety.regular(databaseURL)
        return try operation(SQLite(databaseURL, readOnly: true))
    }

    public func types() throws -> [CatalogType] {
        try read { db in
            try db.rows("SELECT type_id, name FROM types ORDER BY name, type_id").map {
                CatalogType(id: $0.text("type_id"), name: $0.text("name"))
            }
        }
    }
    public func eggGroups() throws -> [EggGroup] {
        try read { db in
            try db.rows("""
                SELECT CAST(groups.value AS INTEGER) AS egg_group_id, COUNT(DISTINCT p.pet_id) AS member_count
                FROM pets p, json_each(p.extra_json, ?) groups
                WHERE p.status = 'active' GROUP BY egg_group_id ORDER BY egg_group_id
                """, [.text("$.egg_group")]).map {
                EggGroup(id: $0.integer("egg_group_id") ?? 0, memberCount: $0.integer("member_count") ?? 0)
            }
        }
    }
    public func searchPets(_ query: PetQuery, handbooksOnly: Bool = false) throws -> [PetSummary] {
        try read { db in
            let keyword = query.keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            var conditions = ["p.status = 'active'", "h.status = 'active'"]
            var args: [SQLValue] = []
            if handbooksOnly { conditions.append("d.default_pet_id = p.pet_id") }
            if !keyword.isEmpty {
                let pattern = SQLValue.text("%\(escapedLike(keyword))%")
                let numeric = keyword.unicodeScalars.allSatisfy { (48...57).contains($0.value) }
                let dex: SQLValue = numeric ? .text(String(repeating: "0", count: max(0, 3 - keyword.count)) + keyword) : .null
                conditions.append("""
                    (p.name LIKE ? ESCAPE '\\' OR p.title LIKE ? ESCAPE '\\'
                    OR EXISTS(SELECT 1 FROM pet_aliases a WHERE a.pet_id = p.pet_id AND a.alias LIKE ? ESCAPE '\\')
                    OR (? IS NOT NULL AND h.dex_no = ?))
                    """)
                args += [pattern, pattern, pattern, dex, dex]
            }
            if !query.typeIDs.isEmpty {
                conditions.append("EXISTS(SELECT 1 FROM pet_types t WHERE t.pet_id = p.pet_id AND t.type_id IN (\(placeholders(query.typeIDs.count))))")
                args += query.typeIDs.map(SQLValue.text)
            }
            if !query.stages.isEmpty {
                conditions.append("p.stage IN (\(placeholders(query.stages.count)))")
                args += query.stages.map(SQLValue.integer)
            }
            if !query.forms.isEmpty {
                let lord = "(COALESCE(p.is_lord_evolution, 0) = 1 OR p.form = '\u{9996}\u{9886}\u{5f62}\u{6001}')"
                let clauses = query.forms.map { form -> String in
                    switch form {
                    case .main: return "d.default_pet_id = p.pet_id"
                    case .regional:
                        return "(COALESCE(TRIM(p.form), '') <> '' AND p.form NOT IN ('\u{672c}\u{6765}\u{7684}\u{6837}\u{5b50}', '\u{539f}\u{672c}\u{7684}\u{6837}\u{5b50}') AND NOT \(lord))"
                    case .lord: return lord
                    }
                }
                conditions.append("(\(clauses.joined(separator: " OR ")))")
            }
            switch query.shiny {
            case .any: break
            case .hasShiny: conditions.append("p.has_shiny = 1")
            case .noShiny: conditions.append("COALESCE(p.has_shiny, 0) = 0")
            }
            if !query.seasons.isEmpty {
                conditions.append("p.belong_season_raw IN (\(placeholders(query.seasons.count)))")
                args += query.seasons.map(SQLValue.text)
            }
            if !query.eggGroupIDs.isEmpty {
                conditions.append("EXISTS(SELECT 1 FROM json_each(p.extra_json, ?) groups WHERE CAST(groups.value AS INTEGER) IN (\(placeholders(query.eggGroupIDs.count))))")
                args += [.text("$.egg_group")] + query.eggGroupIDs.map(SQLValue.integer)
            }
            let order: String
            switch query.sort {
            case .handbook: order = "h.sort_order IS NULL, h.sort_order, h.handbook_id, p.pet_id"
            case .name: order = "p.name, p.pet_id"
            case .attack: order = "p.atk IS NULL, p.atk DESC, p.pet_id"
            case .magicAttack: order = "p.spa IS NULL, p.spa DESC, p.pet_id"
            case .speed: order = "p.spe IS NULL, p.spe DESC, p.pet_id"
            }
            args += [.text(keyword), .text(keyword), .integer(min(200, max(1, query.limit))), .integer(max(0, query.offset))]
            return try db.rows("""
                \(Self.petSelect) WHERE \(conditions.joined(separator: " AND "))
                ORDER BY CASE WHEN p.name = ? OR p.title = ? THEN 0 ELSE 1 END, \(order) LIMIT ? OFFSET ?
                """, args).map { try pet($0, db) }
        }
    }
    public func petDetail(_ id: String) throws -> PetDetail {
        try read { db in
            guard let row = try db.rows("\(Self.petSelect) WHERE p.pet_id = ? AND p.status = 'active'", [.text(id)]).first else {
                throw HandbookError("not_found", "This creature is unavailable in the current Catalog.")
            }
            return try PetDetail(
                summary: pet(row, db), className: row.optionalText("class_name"),
                description: row.optionalText("description"), height: row.optionalText("height_text"),
                weight: row.optionalText("weight_text"), starlight: row.integer("starlight"),
                reviewGold: row.integer("review_gold"), canDoubleRide: row.bool("can_double_ride"),
                stats: [("HP", "hp"), ("Attack", "atk"), ("Defense", "def"),
                        ("Magic attack", "spa"), ("Magic defense", "spd"), ("Speed", "spe")].map {
                    BaseStat(id: $0.0, value: row.integer($0.1))
                }, sources: sources(db, kind: "pet", id: id)
            )
        }
    }
    public func forms(_ handbookID: String) throws -> [PetSummary] {
        try read { db in
            try db.rows("\(Self.petSelect) WHERE p.handbook_id = ? AND p.status = 'active' ORDER BY is_default DESC, p.pet_id", [.text(handbookID)])
                .map { try pet($0, db) }
        }
    }
    public func petSkills(_ id: String) throws -> PetSkillBundle {
        try read { db in
            guard try !db.rows("SELECT 1 FROM pets WHERE pet_id = ? AND status = 'active'", [.text(id)]).isEmpty else {
                throw HandbookError("not_found", "This creature is unavailable in the current Catalog.")
            }
            let features = try db.rows("""
                SELECT s.*, 1 AS is_feature FROM pet_feature_skills f
                JOIN skills s ON s.skill_id = f.skill_id WHERE f.pet_id = ?
                """, [.text(id)])
            let learned = try db.rows("""
                SELECT s.*, x.source_kind, x.learn_level, x.source_stage, x.blood_raw, x.requirement_text, x.ordinal,
                EXISTS(SELECT 1 FROM pet_feature_skills f WHERE f.skill_id = s.skill_id) AS is_feature
                FROM pet_skill_sources x JOIN skills s ON s.skill_id = x.skill_id WHERE x.pet_id = ?
                ORDER BY CASE x.source_kind WHEN 'native' THEN 0 WHEN 'blood' THEN 1 WHEN 'stone' THEN 2 ELSE 3 END,
                x.ordinal, s.skill_id
                """, [.text(id)]).map {
                    LearnableSkill(skill: skill($0), sourceKind: $0.text("source_kind"), ordinal: $0.integer("ordinal") ?? 0,
                                   learnLevel: $0.integer("learn_level"), sourceStage: $0.integer("source_stage"),
                                   bloodRaw: $0.optionalText("blood_raw"), requirement: $0.optionalText("requirement_text"))
                }
            return PetSkillBundle(feature: features.first.map(skill), learned: learned)
        }
    }
    public func searchSkills(_ query: SkillQuery) throws -> [SkillSummary] {
        try read { db in
            let keyword = query.keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            var conditions = ["s.status = 'active'"]
            var args: [SQLValue] = []
            if !keyword.isEmpty {
                conditions.append("s.name LIKE ? ESCAPE '\\'")
                args.append(.text("%\(escapedLike(keyword))%"))
            }
            switch query.filter {
            case .all: break
            case .features: conditions.append("EXISTS(SELECT 1 FROM pet_feature_skills f WHERE f.skill_id = s.skill_id)")
            case .learnable: conditions.append("EXISTS(SELECT 1 FROM pet_skill_sources x WHERE x.skill_id = s.skill_id)")
            }
            if !query.skillTypes.isEmpty {
                var clauses: [String] = []
                for type in query.skillTypes {
                    switch type {
                    case "\u{7269}\u{653b}", "\u{9b54}\u{653b}":
                        clauses.append("json_extract(s.extra_json, '$.damage_class') = ?")
                    case "\u{9632}\u{5fa1}", "\u{72b6}\u{6001}": clauses.append("s.category = ?")
                    default: clauses.append("0 = 1"); continue
                    }
                    args.append(.text(type))
                }
                conditions.append("(\(clauses.joined(separator: " OR ")))")
            }
            if !query.typeIDs.isEmpty {
                conditions.append("s.type_id IN (\(placeholders(query.typeIDs.count)))")
                args += query.typeIDs.map(SQLValue.text)
            }
            if !query.tags.isEmpty {
                let tags = query.tags.map(Self.tagClause)
                conditions.append("(\(tags.map(\.0).joined(separator: " OR ")))")
                args += tags.flatMap(\.1)
            }
            args += [.text(keyword), .integer(min(200, max(1, query.limit))), .integer(max(0, query.offset))]
            return try db.rows("""
                \(Self.skillSelect) WHERE \(conditions.joined(separator: " AND "))
                ORDER BY CASE WHEN s.name = ? THEN 0 ELSE 1 END, s.name, s.skill_id LIMIT ? OFFSET ?
                """, args).map(skill)
        }
    }
    public func skillDetail(_ id: String) throws -> SkillDetail {
        try read { db in
            guard let row = try db.rows("\(Self.skillSelect) WHERE s.skill_id = ? AND s.status = 'active'", [.text(id)]).first else {
                throw HandbookError("not_found", "This skill is unavailable in the current Catalog.")
            }
            let notes = try db.rows("SELECT note_id FROM skill_description_notes WHERE skill_id = ? ORDER BY ordinal", [.text(id)])
            return SkillDetail(summary: skill(row), target: row.optionalText("target_text"),
                               descriptionNoteIDs: notes.map { $0.text("note_id") }, sources: try sources(db, kind: "skill", id: id))
        }
    }
    public func skillsForNote(_ id: String) throws -> [SkillSummary] {
        try read { db in
            try db.rows("""
                \(Self.skillSelect) WHERE s.status = 'active'
                AND EXISTS(SELECT 1 FROM skill_description_notes n WHERE n.skill_id = s.skill_id AND n.note_id = ?)
                ORDER BY is_feature DESC, s.name, s.skill_id
                """, [.text(id)]).map(skill)
        }
    }
    public func skillUsers(_ id: String, feature: Bool) throws -> [SkillUser] {
        try read { db in
            let fields = feature ? "'feature' AS source_kind, NULL AS learn_level, NULL AS source_stage, NULL AS blood_raw, NULL AS requirement_text, 0 AS ordinal" :
                "x.source_kind, x.learn_level, x.source_stage, x.blood_raw, x.requirement_text, x.ordinal"
            let join = feature ? "JOIN pet_feature_skills x ON x.pet_id = p.pet_id" : "JOIN pet_skill_sources x ON x.pet_id = p.pet_id"
            return try db.rows("""
                SELECT p.*, h.dex_no, CASE WHEN d.default_pet_id = p.pet_id THEN 1 ELSE 0 END AS is_default, \(fields)
                \(Self.petFrom) \(join) WHERE x.skill_id = ? AND p.status = 'active'
                ORDER BY h.sort_order, p.pet_id, source_kind, ordinal
                """, [.text(id)]).map {
                    try SkillUser(pet: pet($0, db), relationship: $0.text("source_kind"), ordinal: $0.integer("ordinal") ?? 0,
                                  learnLevel: $0.integer("learn_level"), sourceStage: $0.integer("source_stage"),
                                  bloodRaw: $0.optionalText("blood_raw"), requirement: $0.optionalText("requirement_text"))
                }
        }
    }
    public func evolutions(_ id: String) throws -> EvolutionGraph {
        try read { db in
            let groups = try db.rows("SELECT evolution_group_id FROM pet_evolution_groups WHERE pet_id = ? ORDER BY evolution_group_id", [.text(id)])
                .map { SQLValue.text($0.text("evolution_group_id")) }
            guard !groups.isEmpty else { return EvolutionGraph(nodes: [], edges: []) }
            let nodes = try db.rows("""
                SELECT DISTINCT p.*, h.dex_no, CASE WHEN d.default_pet_id = p.pet_id THEN 1 ELSE 0 END AS is_default
                \(Self.petFrom) JOIN pet_evolution_groups m ON m.pet_id = p.pet_id
                WHERE m.evolution_group_id IN (\(placeholders(groups.count))) ORDER BY m.source_order, p.pet_id
                """, groups).map { try pet($0, db) }
            let edges = try db.rows("""
                SELECT * FROM evolution_edges WHERE evolution_group_id IN (\(placeholders(groups.count)))
                ORDER BY evolution_group_id, ordinal
                """, groups).map {
                    EvolutionEdge(groupID: $0.text("evolution_group_id"), fromID: $0.text("from_pet_id"),
                                  toID: $0.text("to_pet_id"), method: $0.text("method_code"),
                                  level: $0.integer("level_requirement"), condition: $0.optionalText("condition_text"),
                                  ordinal: $0.integer("ordinal") ?? 0)
                }
            return EvolutionGraph(nodes: nodes, edges: edges)
        }
    }
    public func info() throws -> CatalogInfo {
        try read { db in
            guard let row = try db.rows("SELECT * FROM catalog_meta WHERE singleton = 1").first else {
                throw HandbookError("catalog_meta", "The Catalog metadata is missing.")
            }
            let revisions = try db.rows("SELECT min(revised_at_utc) AS earliest, max(revised_at_utc) AS latest FROM source_revisions").first ?? [:]
            let coverage = try JSONDecoder().decode([String: Bool].self, from: Data(row.text("coverage_json").utf8))
            return CatalogInfo(datasetID: row.text("dataset_id"), schemaVersion: row.integer("schema_version") ?? 0,
                               dataVersion: row.integer("data_version") ?? 0, snapshotID: row.text("snapshot_id"),
                               builtAt: row.text("built_at_utc"), adapterVersion: row.text("adapter_version"),
                               builderVersion: row.text("builder_version"), coverage: coverage,
                               earliestRevision: revisions.text("earliest"), latestRevision: revisions.text("latest"))
        }
    }

    private static let petFrom = """
        FROM pets p JOIN handbook_entries h ON h.handbook_id = p.handbook_id
        JOIN handbook_display d ON d.handbook_id = p.handbook_id
        """
    private static let petSelect = "SELECT p.*, h.dex_no, CASE WHEN d.default_pet_id = p.pet_id THEN 1 ELSE 0 END AS is_default \(petFrom)"
    private static let skillSelect = "SELECT s.*, EXISTS(SELECT 1 FROM pet_feature_skills f WHERE f.skill_id = s.skill_id) AS is_feature FROM skills s"

    private func pet(_ row: SQLRow, _ db: SQLite) throws -> PetSummary {
        let types = try db.rows("""
            SELECT t.name FROM pet_types p JOIN types t ON t.type_id = p.type_id
            WHERE p.pet_id = ? ORDER BY p.slot
            """, [.text(row.text("pet_id"))]).map { $0.text("name") }
        return PetSummary(id: row.text("pet_id"), handbookID: row.text("handbook_id"), dexNo: row.text("dex_no"),
                          name: row.text("name"), title: row.text("title"), form: row.optionalText("form"), types: types,
                          illustrationKey: row.optionalText("illustration_key"), isDefaultForm: row.bool("is_default") ?? false,
                          stage: row.integer("stage"), hasShiny: row.bool("has_shiny") ?? false,
                          season: row.optionalText("belong_season_raw"), isLordEvolution: row.bool("is_lord_evolution") ?? false)
    }
    private func skill(_ row: SQLRow) -> SkillSummary {
        let extra = (try? JSONSerialization.jsonObject(with: Data(row.text("extra_json").utf8))) as? [String: Any]
        return SkillSummary(id: row.text("skill_id"), name: row.text("name"), category: row.optionalText("category"),
                            damageClass: extra?["damage_class"] as? String, description: row.optionalText("description"),
                            iconKey: row.optionalText("icon_key"), element: row.optionalText("element_raw"),
                            energyValue: row["energy_value"]?.number, energyText: row.optionalText("energy_text"),
                            powerValue: row["power_value"]?.number, powerText: row.optionalText("power_text"),
                            isFeature: row.bool("is_feature") ?? false)
    }
    private func sources(_ db: SQLite, kind: String, id: String) throws -> [SourceReference] {
        try db.rows("""
            SELECT r.source_name, r.revision_id, r.license_id, r.source_url FROM entity_sources e
            JOIN source_revisions r ON r.source_ref = e.source_ref
            WHERE e.entity_kind = ? AND e.entity_id = ? ORDER BY r.source_key, r.revision_id
            """, [.text(kind), .text(id)]).map {
                SourceReference(name: $0.text("source_name"), revisionID: $0.integer("revision_id") ?? 0,
                                licenseID: $0.text("license_id"), url: $0.text("source_url"))
            }
    }
    private static func tagClause(_ tag: String) -> (String, [SQLValue]) {
        switch tag {
        case "\u{5f02}\u{5e38}":
            return ("EXISTS(SELECT 1 FROM skill_description_notes n WHERE n.skill_id = s.skill_id AND n.note_id IN ('1001','1002','1004','1008'))", [])
        case "\u{5e94}\u{5bf9}":
            return ("EXISTS(SELECT 1 FROM skill_description_notes n WHERE n.skill_id = s.skill_id AND n.note_id IN ('1015','1017'))", [])
        case "\u{56de}\u{8840}":
            return ("(s.description LIKE ? OR s.description LIKE ?)", [.text("%\u{56de}\u{590d}%\u{751f}\u{547d}%"), .text("%\u{5438}\u{8840}%")])
        case "\u{56de}\u{80fd}": return ("s.description LIKE ?", [.text("%\u{56de}\u{590d}%\u{80fd}\u{91cf}%")])
        case "\u{5148}\u{624b}": return ("(s.description LIKE ? AND s.category <> '\u{9632}\u{5fa1}')", [.text("%\u{5148}\u{624b}%")])
        case "\u{79bb}\u{573a}":
            return ("(s.description LIKE ? OR s.description LIKE ? OR s.description LIKE ?)", [.text("%\u{79bb}\u{573a}%"), .text("%\u{8131}\u{79bb}%"), .text("%\u{8fd4}\u{573a}%")])
        default:
            let exact = ["\u{5370}\u{8bb0}", "\u{9a71}\u{6563}", "\u{5929}\u{6c14}", "\u{9009}\u{62e9}", "\u{5de7}\u{53d8}",
                         "\u{8fde}\u{51fb}", "\u{840c}\u{5316}", "\u{5f15}\u{7535}", "\u{8fc5}\u{6377}", "\u{4f20}\u{52a8}",
                         "\u{8ff8}\u{53d1}", "\u{5949}\u{732e}", "\u{6253}\u{65ad}"]
            if exact.contains(tag) { return ("s.description LIKE ?", [.text("%\(tag)%")]) }
            if tag == "\u{5f3a}\u{5316}" { return ("s.description LIKE ?", [.text("%\u{6c38}\u{4e45}%")]) }
            return ("0 = 1", [])
        }
    }
}
