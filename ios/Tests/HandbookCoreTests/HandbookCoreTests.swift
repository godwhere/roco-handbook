import XCTest
@testable import HandbookCore

final class HandbookCoreTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
    }
    private var assets: URL { root.appendingPathComponent("app/assets") }
    private func temporary() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("roco-native-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
    private func user(_ support: URL) throws -> UserRepository {
        try UserRepository(supportURL: support, schemaSQL: String(contentsOf: root.appendingPathComponent("schemas/user_v1.sql")))
    }
    private func typeFixture(_ value: [String: Any]) throws -> AssetRepository {
        let fixture = try temporary()
        let wiki = fixture.appendingPathComponent("wiki")
        try FileManager.default.createDirectory(at: wiki, withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: value).write(to: wiki.appendingPathComponent("type-relations-v1.json"))
        return AssetRepository(assetRoot: fixture)
    }
    private func referenceValue(_ kind: ReferenceCatalogKind) -> [String: Any] {
        let id: String
        switch kind {
        case .items: id = "item_0123456789ab"
        case .research: id = "pt_000001_000001"
        case .medals: id = "medal_1"
        case .trials: id = "gt_0123456789abcdef"
        case .habitats: id = "p-0123456789abcdef"
        }
        let group = kind == .research ? "handbook_000001" : "source-group"
        var entry: [String: Any] = [
            "id": id, "name": "Canonical source name", "group_id": group, "visible": true,
            "sections": [["title": "Source conditions", "lines": ["First condition", "Second condition"]]],
            "links": [["kind": "pet", "id": "pet_000007", "name": "Source creature"],
                      ["kind": "item", "id": "item_0123456789ab", "name": "Source item"]],
            "image_path": "wiki/references/v1/icons/source.png", "raw": ["unknown": [1, 2]],
        ]
        if kind.supportsProgress { entry["progress_id"] = id }
        if kind == .research { entry["handbook_id"] = group }
        return [
            "contract_version": 1, "dataset_id": "roco-world-zh-cn", "snapshot_id": "reference-fixture", "kind": kind.rawValue,
            "sources": [["title": "Module:ReferenceFixture", "page_id": 101, "revision_id": 202,
                         "revised_at_utc": "2026-10-26T00:00:00Z", "sha1": String(repeating: "a", count: 40),
                         "sha256": String(repeating: "b", count: 64),
                         "url": "https://wiki.biligame.com/nrc/index.php?title=Module%3AReferenceFixture&oldid=202"]],
            "groups": [["id": group, "title": "Source group", "image_path": "wiki/v4/ui/types/fire.png"]],
            "entries": [entry],
        ]
    }
    private func referenceFixture(_ kind: ReferenceCatalogKind, value: [String: Any]) throws -> AssetRepository {
        let fixture = try temporary()
        let directory = fixture.appendingPathComponent("wiki/references/v1")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: value).write(to: directory.appendingPathComponent("\(kind.rawValue).json"))
        return AssetRepository(assetRoot: fixture)
    }
    private var catalog: CatalogRepository { CatalogRepository(databaseURL: assets.appendingPathComponent("catalog/catalog.db")) }

    func testBundledCatalogMatchesImmutableRelease() throws {
        for filename in ["catalog.db", "bundled_catalog.json", "ATTRIBUTION.txt"] {
            XCTAssertEqual(try Data(contentsOf: assets.appendingPathComponent("catalog/\(filename)")),
                           try Data(contentsOf: root.appendingPathComponent("data/release/3/assets/catalog/\(filename)")))
        }
        XCTAssertEqual(try Data(contentsOf: assets.appendingPathComponent("database/user_v1.sql")),
                       try Data(contentsOf: root.appendingPathComponent("schemas/user_v1.sql")))
    }
    func testCompleteConcreteFormAndHandbookPagination() async throws {
        var query = PetQuery()
        var pets: [PetSummary] = []
        while true {
            let page = try await catalog.searchPets(query)
            pets += page
            if page.count < query.limit { break }
            query.offset += page.count
        }
        XCTAssertEqual(pets.count, 633)
        XCTAssertEqual(Set(pets.map(\.id)).count, 633)
        query.offset = 0; query.limit = 200
        var handbooks: [PetSummary] = []
        while true {
            let page = try await catalog.searchPets(query, handbooksOnly: true)
            handbooks += page
            if page.count < query.limit { break }
            query.offset += page.count
        }
        XCTAssertEqual(handbooks.count, 468)
        XCTAssertTrue(handbooks.allSatisfy(\.isDefaultForm))
    }
    func testSearchBindsValuesAndEscapesWildcards() async throws {
        for keyword in ["%", "_", "' OR 1=1 --"] {
            var query = PetQuery(); query.keyword = keyword
            let pets = try await catalog.searchPets(query)
            XCTAssertTrue(pets.isEmpty)
            var skills = SkillQuery(); skills.keyword = keyword; skills.filter = .all
            let result = try await catalog.searchSkills(skills)
            XCTAssertTrue(result.isEmpty)
        }
        var number = PetQuery(); number.keyword = "4"
        let pets = try await catalog.searchPets(number)
        XCTAssertFalse(pets.isEmpty)
        XCTAssertTrue(pets.allSatisfy { $0.dexNo == "004" })
    }
    func testThreeFormIdentityAndEvidenceBackedEvolution() async throws {
        let detail = try await catalog.petDetail("pet_000007")
        let forms = try await catalog.forms(detail.summary.handbookID)
        XCTAssertEqual(forms.count, 3)
        XCTAssertEqual(Set(forms.map(\.id)).count, 3)
        let graph = try await catalog.evolutions(detail.summary.id)
        XCTAssertFalse(graph.edges.isEmpty)
        for edge in graph.edges {
            XCTAssertTrue(graph.nodes.contains { $0.id == edge.fromID })
            XCTAssertTrue(graph.nodes.contains { $0.id == edge.toID })
        }
        XCTAssertFalse(detail.sources.isEmpty)
        XCTAssertEqual(detail.summary.dexNo, "004")
    }
    func testThreeColumnDefaultAndSavedLayoutCompatibility() async throws {
        let support = try temporary()
        let saved = try user(support)
        let initial = try await saved.layout()
        XCTAssertEqual(initial, .threeColumn)
        for layout in PetCatalogLayout.allCases {
            try await saved.setLayout(layout)
            let reopened = try user(support)
            let actual = try await reopened.layout()
            XCTAssertEqual(actual, layout)
        }
        let db = try SQLite(saved.databaseURL, readOnly: false)
        for json in ["[]", "123", "\"unsupported\""] {
            try db.execute("UPDATE settings SET value_json = ? WHERE setting_key = 'pet_catalog_layout'", [.text(json)])
            let actual = try await saved.layout()
            XCTAssertEqual(actual, .threeColumn)
        }
    }
    func testSkillLayoutDefaultsPersistenceAndCreaturePreferenceIsolation() async throws {
        let support = try temporary()
        let saved = try user(support)
        let initial = try await saved.skillLayout()
        XCTAssertEqual(initial, .twoColumn)
        try await saved.setLayout(.list)
        let ref = ObjectRef(type: .pet, objectID: "pet_000001", name: "Saved creature")
        try await saved.setFavorite(ref, enabled: true)
        for layout in SkillCatalogLayout.allCases {
            try await saved.setSkillLayout(layout)
            let reopened = try user(support)
            let actual = try await reopened.skillLayout()
            let petLayout = try await reopened.layout()
            let favorite = try await reopened.isFavorite(ref)
            XCTAssertEqual(actual, layout)
            XCTAssertEqual(petLayout, .list)
            XCTAssertTrue(favorite)
        }
        let db = try SQLite(saved.databaseURL, readOnly: false)
        for json in ["[]", "123", "null", "\"unsupported\""] {
            try db.execute("UPDATE settings SET value_json = ? WHERE setting_key = 'skill_catalog_layout'", [.text(json)])
            let actual = try await saved.skillLayout()
            XCTAssertEqual(actual, .twoColumn)
        }
    }
    func testInterfaceLanguageUsesPreferredMatchingAndExplicitOverrides() {
        XCTAssertEqual(InterfaceLanguage.allCases.map(\.rawValue), ["system", "zh-Hans", "en"])
        XCTAssertEqual(InterfaceLanguage.system.localizationIdentifier(preferredLanguages: ["zh-Hans-CN"]), "zh-Hans")
        XCTAssertEqual(InterfaceLanguage.system.localizationIdentifier(preferredLanguages: ["en-US"]), "en")
        XCTAssertEqual(InterfaceLanguage.system.localizationIdentifier(preferredLanguages: ["fr-FR"]), "en")
        XCTAssertEqual(InterfaceLanguage.system.localizationIdentifier(preferredLanguages: []), "en")
        XCTAssertEqual(InterfaceLanguage.english.localizationIdentifier(preferredLanguages: ["zh-Hans"]), "en")
        XCTAssertEqual(InterfaceLanguage.simplifiedChinese.localizationIdentifier(preferredLanguages: ["en-US"]), "zh-Hans")
    }
    func testInterfaceLanguagePersistsWithoutChangingOtherPersonalData() async throws {
        let support = try temporary()
        let saved = try user(support)
        let initial = try await saved.interfaceLanguage()
        XCTAssertEqual(initial, .system)
        try await saved.setLayout(.list)
        try await saved.setSkillLayout(.detailed)
        let ref = ObjectRef(type: .pet, objectID: "pet_000001", name: "Saved creature")
        try await saved.setFavorite(ref, enabled: true)
        let noteID = try await saved.saveNote(ref, content: "Language selection must preserve this note.")
        try await saved.setCollected("handbook_000001", name: "Saved creature", collected: true)
        for language in InterfaceLanguage.allCases {
            try await saved.setInterfaceLanguage(language)
            let reopened = try user(support)
            let actual = try await reopened.interfaceLanguage()
            let petLayout = try await reopened.layout()
            let skillLayout = try await reopened.skillLayout()
            let favorite = try await reopened.isFavorite(ref)
            let notes = try await reopened.notes(ref)
            let collected = try await reopened.isCollected("handbook_000001")
            XCTAssertEqual(actual, language)
            XCTAssertEqual(petLayout, .list)
            XCTAssertEqual(skillLayout, .detailed)
            XCTAssertTrue(favorite)
            XCTAssertTrue(collected)
            XCTAssertEqual(notes.map(\.id), [noteID])
            XCTAssertEqual(notes.first?.content, "Language selection must preserve this note.")
        }
        let db = try SQLite(saved.databaseURL, readOnly: false)
        for json in ["[]", "123", "null", "{", "", "\"unsupported\"", "\"zh-CN\""] {
            try db.execute("UPDATE settings SET value_json = ? WHERE setting_key = 'interface_language'", [.text(json)])
            let actual = try await saved.interfaceLanguage()
            XCTAssertEqual(actual, .system)
        }
        XCTAssertEqual(try db.rows("PRAGMA user_version").first?.integer("user_version"), 1)
    }
    func testBundledLanguageLookupFallsBackWithoutChangingSystemLanguageOrGameText() throws {
        let directory = try temporary().appendingPathComponent("LanguageFixture.bundle")
        let resources = directory.appendingPathComponent("Contents/Resources")
        for language in ["en", "zh-Hans"] {
            let target = resources.appendingPathComponent("\(language).lproj")
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: root.appendingPathComponent("ios/App/\(language).lproj/Localizable.strings"),
                                             to: target.appendingPathComponent("Localizable.strings"))
        }
        let info: [String: Any] = ["CFBundleIdentifier": "world.roco.tests.language", "CFBundlePackageType": "BNDL",
                                  "CFBundleDevelopmentRegion": "en", "CFBundleLocalizations": ["en", "zh-Hans"]]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            .write(to: directory.appendingPathComponent("Contents/Info.plist"))
        let english = resources.appendingPathComponent("en.lproj/Localizable.strings")
        let source = try String(contentsOf: english)
        try (source + "\n\"Language fixture fallback\" = \"English fallback\";\n")
            .write(to: english, atomically: true, encoding: .utf8)
        let bundle = try XCTUnwrap(Bundle(url: directory))
        let systemBefore = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String]
        let localizer = HandbookLocalization(bundle: bundle, language: .english, preferredLanguages: ["zh-Hans"])
        XCTAssertEqual(localizer.string(forKey: "Tools"), "Tools")
        XCTAssertTrue(localizer.locale.identifier.hasPrefix("en"))
        localizer.use(.simplifiedChinese, preferredLanguages: ["en-US"])
        XCTAssertEqual(localizer.string(forKey: "Tools"), "\u{5de5}\u{5177}")
        XCTAssertTrue(localizer.locale.identifier.hasPrefix("zh"))
        XCTAssertEqual(localizer.string(forKey: "Language fixture fallback"), "English fallback")
        XCTAssertEqual(localizer.string(forKey: "Missing fixture key"), "Missing fixture key")
        let canonicalName = "\u{55b5}\u{55b5}"
        XCTAssertEqual(localizer.string(forKey: canonicalName), canonicalName)
        localizer.use(.system, preferredLanguages: ["en-US"])
        XCTAssertEqual(localizer.string(forKey: "Tools"), "Tools")
        XCTAssertEqual(UserDefaults.standard.array(forKey: "AppleLanguages") as? [String], systemBefore)
    }
    func testDetailEggGroupsAndMeasurementsMatchStoredSource() async throws {
        let db = try SQLite(assets.appendingPathComponent("catalog/catalog.db"), readOnly: true)
        let rows = try db.rows("SELECT pet_id, extra_json FROM pets WHERE status = 'active'")
        var missingSizeCount = 0
        for row in rows {
            let extra = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(row.text("extra_json").utf8)) as? [String: Any])
            let detail = try await catalog.petDetail(row.text("pet_id"))
            XCTAssertEqual(detail.eggGroups, extra["egg_group"] as? [Int] ?? [])
            if let size = extra["egg_size"] as? [String: Any] {
                XCTAssertEqual(detail.eggSize?.minimum, size["min"] as? Double)
                XCTAssertEqual(detail.eggSize?.maximum, size["max"] as? Double)
                XCTAssertEqual(detail.eggSize?.miniMaximum, size["mini_max"] as? Double)
                XCTAssertEqual(detail.eggSize?.hugeMinimum, size["huge_min"] as? Double)
                XCTAssertEqual(detail.eggSize?.unit, size["unit"] as? String)
            } else {
                XCTAssertNil(detail.eggSize)
                missingSizeCount += 1
            }
        }
        XCTAssertEqual(rows.count, 633)
        XCTAssertEqual(missingSizeCount, 47)
    }
    func testSharedLearnsetAndAllAcquisitionConditionsRemainTraceable() async throws {
        let db = try SQLite(assets.appendingPathComponent("catalog/catalog.db"), readOnly: true)
        let shared = try db.rows("""
            SELECT learnset_id FROM pet_learnsets GROUP BY learnset_id HAVING COUNT(*) > 1 LIMIT 1
            """).first!.text("learnset_id")
        let petIDs = try db.rows("SELECT pet_id FROM pet_learnsets WHERE learnset_id = ? ORDER BY pet_id", [.text(shared)]).map { $0.text("pet_id") }
        for id in petIDs {
            let bundle = try await catalog.petSkills(id)
            let rows = try db.rows("SELECT * FROM pet_skill_sources WHERE pet_id = ? ORDER BY source_kind, ordinal", [.text(id)])
            XCTAssertEqual(bundle.learned.count, rows.count)
            for row in rows {
                let skill = bundle.learned.first { $0.skill.id == row.text("skill_id") && $0.sourceKind == row.text("source_kind") && $0.ordinal == row.integer("ordinal") }
                XCTAssertNotNil(skill)
                XCTAssertEqual(skill?.learnLevel, row.integer("learn_level"))
                XCTAssertEqual(skill?.sourceStage, row.integer("source_stage"))
                XCTAssertEqual(skill?.bloodRaw, row.optionalText("blood_raw"))
                XCTAssertEqual(skill?.requirement, row.optionalText("requirement_text"))
            }
        }
        let feature = try await catalog.petSkills("pet_000007")
        XCTAssertEqual(feature.feature?.id, "skill_000003")
    }
    func testSkillFiltersAndDescriptionReferences() async throws {
        var query = SkillQuery(); query.filter = .all; query.limit = 200
        var all: [SkillSummary] = []
        while true {
            let page = try await catalog.searchSkills(query); all += page
            if page.count < query.limit { break }; query.offset += page.count
        }
        XCTAssertEqual(all.count, 825)
        query.offset = 0; query.filter = .features
        let features = try await catalog.searchSkills(query)
        XCTAssertTrue(features.allSatisfy(\.isFeature))
        query.skillTypes = ["unsupported"]
        let empty = try await catalog.searchSkills(query)
        XCTAssertTrue(empty.isEmpty)
        let noteSkills = try await catalog.skillsForNote("1001")
        XCTAssertFalse(noteSkills.isEmpty)
        for skill in noteSkills.prefix(4) {
            let detail = try await catalog.skillDetail(skill.id)
            XCTAssertTrue(detail.descriptionNoteIDs.contains("1001"))
        }
    }
    func testShinySeasonStageTypeAndEggGroupFilters() async throws {
        var query = PetQuery(); query.shiny = .hasShiny; query.limit = 200
        let pets = try await catalog.searchPets(query)
        XCTAssertEqual(pets.count, 197)
        XCTAssertTrue(pets.allSatisfy(\.hasShiny))
        let types = try await catalog.types()
        XCTAssertEqual(types.count, 18)
        query.typeIDs = [types[0].id]
        let filtered = try await catalog.searchPets(query)
        XCTAssertTrue(filtered.allSatisfy { $0.types.contains(types[0].name) && $0.hasShiny })
        let groups = try await catalog.eggGroups()
        XCTAssertFalse(groups.isEmpty)
        query = PetQuery(); query.eggGroupIDs = [groups[0].id]; query.limit = 200
        let eggs = try await catalog.searchPets(query)
        XCTAssertEqual(eggs.count, min(200, groups[0].memberCount))
    }
    func testNativeInstallerReusesFlutterPointerAndProtectsUserData() async throws {
        let support = try temporary()
        let bundle = try CatalogBundle.load(assetRoot: assets)
        let legacy = try CatalogBundle.load(assetRoot: root.appendingPathComponent("data/release/2/assets"))
        let directory = support.appendingPathComponent("catalogs")
        let state = support.appendingPathComponent("catalog-state")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: state, withIntermediateDirectories: true)
        let filename = "catalog-v2-s1-dce0d3376611.db"
        try legacy.database.write(to: directory.appendingPathComponent(filename))
        try legacy.attribution.write(to: directory.appendingPathComponent("catalog-v2-s1-dce0d3376611.attribution.txt"))
        let flutterPointer: [String: Any] = [
            "pointer_version": 2, "dataset_id": "roco-world-zh-cn", "schema_version": 1, "data_version": 2,
            "snapshot_id": "snapshot-dad7cd7d5ce73236", "database_bytes": legacy.database.count,
            "database_sha256": legacy.manifest.databaseSha256, "coverage": legacy.manifest.coverage, "file_name": filename,
            "attribution_bytes": legacy.attribution.count, "attribution_sha256": sha256(legacy.attribution),
        ]
        try JSONSerialization.data(withJSONObject: flutterPointer).write(to: state.appendingPathComponent("active_catalog.json"))
        let installer = CatalogInstaller(supportURL: support)
        let installed = try await installer.prepare(legacy)
        XCTAssertEqual(installed.outcome, "Opened the current validated Catalog")
        let saved = try user(support)
        let ref = ObjectRef(type: .pet, objectID: "pet_000007", name: "Saved creature")
        let legacyCatalog = CatalogRepository(databaseURL: root.appendingPathComponent("data/release/2/assets/catalog/catalog.db"))
        let legacySkill = try await legacyCatalog.skillDetail("skill_000208")
        let skillRef = ObjectRef(type: .skill, objectID: legacySkill.summary.id, name: legacySkill.summary.name)
        try await saved.setFavorite(ref, enabled: true)
        try await saved.setFavorite(skillRef, enabled: true)
        try await saved.setCollected("handbook_000004", name: "Saved entry", collected: true)
        _ = try await saved.saveNote(ref, content: "Keep this note")
        try await saved.setLayout(.list)
        try await saved.setReferenceProgress(.research, id: "pt_000001_000001", completed: true)
        try await saved.setReferenceProgress(.trials, id: "gt_0123456789abcdef", completed: true)
        let before = try Data(contentsOf: saved.databaseURL)
        let reused = try await installer.prepare(bundle)
        XCTAssertNotEqual(installed.databaseURL, reused.databaseURL)
        XCTAssertEqual(reused.manifest.dataVersion, 3)
        let refreshedSkill = try await catalog.skillDetail(skillRef.objectID)
        XCTAssertEqual(refreshedSkill.summary.name, skillRef.name)
        let restored = try await installer.prepare(bundle, restore: true)
        XCTAssertEqual(restored.manifest.dataVersion, 3)
        XCTAssertEqual(before, try Data(contentsOf: saved.databaseURL))
        let reopened = try user(support)
        let favorites = try await reopened.favorites()
        let notes = try await reopened.notes(ref)
        let layout = try await reopened.layout()
        let research = try await reopened.referenceProgress(.research)
        let trials = try await reopened.referenceProgress(.trials)
        XCTAssertEqual(Set(favorites.map(\.object)), Set([ref, skillRef]))
        XCTAssertEqual(notes.map(\.content), ["Keep this note"])
        XCTAssertEqual(layout, .list)
        XCTAssertEqual(research, ["pt_000001_000001"])
        XCTAssertEqual(trials, ["gt_0123456789abcdef"])
    }
    func testFailedCandidateDoesNotChangeActivePointer() async throws {
        let support = try temporary()
        let bundle = try CatalogBundle.load(assetRoot: assets)
        let installer = CatalogInstaller(supportURL: support)
        _ = try await installer.prepare(bundle)
        let pointer = support.appendingPathComponent("catalog-state/active_catalog.json")
        let before = try Data(contentsOf: pointer)
        let invalid = try CatalogBundle(manifest: Data(contentsOf: assets.appendingPathComponent("catalog/bundled_catalog.json")),
                                        database: Data("damaged".utf8), attribution: bundle.attribution)
        do { _ = try await installer.prepare(invalid, restore: true); XCTFail("Invalid bytes must fail") } catch {}
        XCTAssertEqual(before, try Data(contentsOf: pointer))
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: support.appendingPathComponent("catalogs").path).contains { $0.contains(".staging") })
    }
    func testDamagedActivePointerRecoversPreviousAndRejectsSymlink() async throws {
        let support = try temporary()
        let bundle = try CatalogBundle.load(assetRoot: assets)
        let installer = CatalogInstaller(supportURL: support)
        let result = try await installer.prepare(bundle)
        let state = support.appendingPathComponent("catalog-state")
        let pointer = state.appendingPathComponent("active_catalog.json")
        try FileManager.default.copyItem(at: pointer, to: state.appendingPathComponent("previous_catalog.json"))
        try Data("damaged".utf8).write(to: pointer)
        let recovered = try await installer.prepare(bundle)
        XCTAssertEqual(recovered.databaseURL, result.databaseURL)
        XCTAssertEqual(recovered.outcome, "Recovered the previous validated Catalog")
        let linked = support.appendingPathComponent("linked")
        try FileManager.default.createSymbolicLink(at: linked, withDestinationURL: support)
        do { _ = try await CatalogInstaller(supportURL: linked).prepare(bundle); XCTFail("A symlink root must fail") } catch {}
    }
    func testUnknownUserSchemaIsPreserved() async throws {
        let support = try temporary()
        let repository = try user(support)
        do { let db = try SQLite(repository.databaseURL, readOnly: false); try db.execute("PRAGMA user_version = 9") }
        let before = try Data(contentsOf: repository.databaseURL)
        XCTAssertThrowsError(try user(support))
        XCTAssertEqual(before, try Data(contentsOf: repository.databaseURL))
    }
    func testNoteEditRequiresOriginalObjectIdentity() async throws {
        let repository = try user(temporary())
        let ref = ObjectRef(type: .skill, objectID: "skill_000003", name: "Saved skill")
        let id = try await repository.saveNote(ref, content: "First draft")
        let other = ObjectRef(type: .pet, objectID: "pet_000007", name: "Other object")
        do { _ = try await repository.saveNote(other, content: "Wrong edit", id: id); XCTFail("Cross-object edits must fail") } catch {}
        _ = try await repository.saveNote(ref, content: "Revised draft", id: id)
        let notes = try await repository.notes(ref)
        XCTAssertEqual(notes.count, 1); XCTAssertEqual(notes[0].content, "Revised draft")
        try await repository.deleteNote(id)
        let deleted = try await repository.notes(ref)
        XCTAssertTrue(deleted.isEmpty)
    }
    func testFrozenToolsAndTypeDamageCap() async throws {
        let repository = AssetRepository(assetRoot: assets)
        let descriptions = try await repository.descriptions()
        let activities = try await repository.activities()
        let fashions = try await repository.fashions()
        XCTAssertEqual(descriptions.entries.count, 54)
        XCTAssertEqual(activities.entries.count, 552)
        XCTAssertEqual(fashions.entries.count, 124)
        XCTAssertEqual(fashions.entries.flatMap(\.variants).count, 248)
        let sources = try await repository.visualSources()
        XCTAssertGreaterThan(sources.count, 1700)
        XCTAssertTrue(sources.contains { $0.name == "RocoDisplay" })
        XCTAssertTrue(sources.contains {
            $0.name == "File:Item_100002.png" && $0.url.hasPrefix("https://patchwiki.biligame.com/images/nrc/")
        })
        let types = try await catalog.types()
        var sawCap = false
        for a in types {
            for b in types where a.id != b.id {
                let result = try await repository.relationships(for: [a.name, b.name])
                XCTAssertTrue(result.incoming.allSatisfy { $0.multiplier <= 3 })
                if result.incoming.contains(where: { $0.multiplier == 3 }) { sawCap = true }
            }
        }
        XCTAssertTrue(sawCap)
    }
    func testReferenceCatalogKeepsSourceOrderLinksAndAdapterVisibility() async throws {
        for kind in ReferenceCatalogKind.allCases {
            var value = referenceValue(kind)
            if kind == .medals {
                var entries = value["entries"] as! [[String: Any]]
                var hidden = entries[0]
                hidden["id"] = "medal_2"
                hidden["visible"] = false
                entries.append(hidden)
                value["entries"] = entries
            }
            let result = try await referenceFixture(kind, value: value).referenceCatalog(kind)
            XCTAssertEqual(result.kind, kind)
            XCTAssertEqual(result.sources.first?.id, "101:202")
            XCTAssertEqual(result.sources.first?.title, "Module:ReferenceFixture")
            XCTAssertEqual(result.visibleEntries.count, 1)
            XCTAssertEqual(result.entries.count, kind == .medals ? 2 : 1)
            XCTAssertEqual(result.entries.first?.name, "Canonical source name")
            XCTAssertEqual(result.entries.first?.sections.first?.lines, ["First condition", "Second condition"])
            XCTAssertEqual(result.entries.first?.links.map(\.kind), ["pet", "item"])
            XCTAssertEqual(result.entries.first?.links.map(\.id), ["pet_000007", "item_0123456789ab"])
            XCTAssertEqual(result.groups.first?.imagePath, "wiki/v4/ui/types/fire.png")
            XCTAssertEqual(kind.supportsProgress, kind == .research || kind == .trials)
        }
    }
    func testBundledReferenceCatalogsResolveExactLinksAndLocalImages() async throws {
        let repository = AssetRepository(assetRoot: assets)
        let items = try await repository.referenceCatalog(.items)
        let itemIDs = Set(items.entries.map(\.id))
        var petIDs: Set<String> = [], handbookIDs: Set<String> = []
        var query = PetQuery(); query.limit = 200
        while true {
            let page = try await catalog.searchPets(query)
            petIDs.formUnion(page.map(\.id)); handbookIDs.formUnion(page.map(\.handbookID))
            if page.count < query.limit { break }
            query.offset += query.limit
        }
        let counts: [ReferenceCatalogKind: Int] = [.items: 1534, .research: 2351, .medals: 60, .trials: 726, .habitats: 109]
        let sourceCounts: [ReferenceCatalogKind: Int] = [.items: 22, .research: 2, .medals: 3, .trials: 1, .habitats: 20]
        var imagePaths: Set<String> = []
        for kind in ReferenceCatalogKind.allCases {
            let value = kind == .items ? items : try await repository.referenceCatalog(kind)
            XCTAssertEqual(value.entries.count, counts[kind])
            XCTAssertEqual(value.sources.count, sourceCounts[kind])
            if kind == .medals { XCTAssertEqual(value.visibleEntries.count, 56) }
            imagePaths.formUnion(value.groups.compactMap(\.imagePath))
            imagePaths.formUnion(value.entries.compactMap(\.imagePath))
            for entry in value.entries {
                if let handbook = entry.handbookId { XCTAssertTrue(handbookIDs.contains(handbook), handbook) }
                for link in entry.links {
                    XCTAssertTrue(link.kind == "pet" ? petIDs.contains(link.id) : itemIDs.contains(link.id), link.id)
                }
            }
        }
        for path in imagePaths { try FileSafety.regular(assets.appendingPathComponent(path)) }
        let unavailable = try XCTUnwrap(items.entries.first { $0.id == "item_a73c5a669658" })
        XCTAssertNil(unavailable.imagePath)
    }
    func testReferenceCatalogRejectsMalformedMembershipLinksAndImages() async throws {
        let original = referenceValue(.research)
        func changed(_ key: String, _ value: Any) -> [String: Any] {
            var result = original; result[key] = value; return result
        }
        func entry(_ key: String, _ value: Any) -> [String: Any] {
            var first = (original["entries"] as! [[String: Any]])[0]
            first[key] = value
            return changed("entries", [first])
        }
        let invalid = [
            changed("contract_version", 2), changed("dataset_id", "other"), changed("snapshot_id", ""), changed("kind", "items"),
            changed("sources", []), changed("groups", []), changed("entries", []),
            changed("groups", (original["groups"] as! [[String: Any]]) + (original["groups"] as! [[String: Any]])),
            changed("entries", (original["entries"] as! [[String: Any]]) + (original["entries"] as! [[String: Any]])),
            entry("id", "pt_1_1"), entry("name", ""), entry("group_id", "missing"), entry("visible", "true"),
            entry("progress_id", "pt_000001_000002"), entry("handbook_id", "handbook_000002"),
            entry("links", [["kind": "skill", "id": "skill_000001", "name": "Wrong link kind"]]),
            entry("links", [["kind": "pet", "id": "pet_000007/other", "name": "Invalid native ID"]]),
            entry("links", [["kind": "item", "id": "item_unknown", "name": "Invalid item ID"]]),
            entry("image_path", "wiki/references/v1/icons/../secret.png"), entry("image_path", "catalog/catalog.png"),
            entry("image_path", "wiki/references/v1/icons\\secret.png"), entry("image_path", "https://example.test/image.png"),
            entry("sections", [["title": "Condition", "lines": ["\u{0}"]]]),
        ]
        for value in invalid {
            let repository = try referenceFixture(.research, value: value)
            do {
                _ = try await repository.referenceCatalog(.research)
                XCTFail("Invalid catalog shape, membership, link identities, and image paths must fail.")
            } catch { XCTAssertEqual((error as? HandbookError)?.code, "reference_contract") }
        }
        for kind in ReferenceCatalogKind.allCases {
            var value = referenceValue(kind)
            var entries = value["entries"] as! [[String: Any]]
            if kind.supportsProgress { entries[0].removeValue(forKey: "progress_id") }
            else { entries[0]["progress_id"] = "pt_000001_000001" }
            value["entries"] = entries
            let repository = try referenceFixture(kind, value: value)
            do {
                _ = try await repository.referenceCatalog(kind)
                XCTFail("Checklist membership must follow the explicit catalog kind.")
            } catch { XCTAssertEqual((error as? HandbookError)?.code, "reference_contract") }
        }
    }
    func testReferenceCatalogRejectsUnfrozenOrMalformedSourceMetadata() async throws {
        let original = referenceValue(.items)
        let source = (original["sources"] as! [[String: Any]])[0]
        let invalid: [(String, Any)] = [
            ("page_id", 0), ("revision_id", 0), ("revised_at_utc", "invalid"), ("sha1", String(repeating: "z", count: 40)),
            ("sha256", "abc"), ("title", "Different title"),
            ("url", "http://wiki.biligame.com/nrc/index.php?title=Module%3AReferenceFixture&oldid=202"),
            ("url", "https://wiki.biligame.com/rocom/index.php?title=Module%3AReferenceFixture&oldid=202"),
            ("url", "https://example.test/nrc/index.php?title=Module%3AReferenceFixture&oldid=202"),
            ("url", "https://wiki.biligame.com/nrc/index.php?title=Module%3AReferenceFixture&oldid=203"),
            ("url", "https://wiki.biligame.com/nrc/index.php?title=Module%3AReferenceFixture&oldid=202#fragment"),
        ]
        for (key, invalidValue) in invalid {
            var changed = source; changed[key] = invalidValue
            var value = original; value["sources"] = [changed]
            let repository = try referenceFixture(.items, value: value)
            do {
                _ = try await repository.referenceCatalog(.items)
                XCTFail("Every source must retain valid identity, hashes, and a matching frozen NRC URL.")
            } catch { XCTAssertEqual((error as? HandbookError)?.code, "reference_contract") }
        }
        var duplicate = original; duplicate["sources"] = [source, source]
        let repository = try referenceFixture(.items, value: duplicate)
        do {
            _ = try await repository.referenceCatalog(.items)
            XCTFail("Duplicate source identities must fail.")
        } catch { XCTAssertEqual((error as? HandbookError)?.code, "reference_contract") }
    }
    func testReferenceProgressPersistsSortedIndependentSetsAndPreservesPersonalData() async throws {
        let support = try temporary()
        let saved = try user(support)
        let initialResearch = try await saved.referenceProgress(.research)
        let initialTrials = try await saved.referenceProgress(.trials)
        XCTAssertTrue(initialResearch.isEmpty && initialTrials.isEmpty)
        let ref = ObjectRef(type: .pet, objectID: "pet_000007", name: "Saved creature")
        try await saved.setFavorite(ref, enabled: true)
        try await saved.setCollected("handbook_000004", name: "Saved entry", collected: true)
        let noteID = try await saved.saveNote(ref, content: "Preserve this note")
        try await saved.setLayout(.list)
        try await saved.setSkillLayout(.detailed)
        try await saved.setInterfaceLanguage(.english)
        let unknown = "pt_999999_999999"
        try await saved.setReferenceProgress(.research, id: unknown, completed: true)
        try await saved.setReferenceProgress(.research, id: "pt_000001_000002", completed: true)
        try await saved.setReferenceProgress(.research, id: "pt_000001_000001", completed: true)
        try await saved.setReferenceProgress(.research, id: "pt_000001_000002", completed: false)
        try await saved.setReferenceProgress(.trials, id: "gt_0123456789abcdef", completed: true)
        let reopened = try user(support)
        let research = try await reopened.referenceProgress(.research)
        let trials = try await reopened.referenceProgress(.trials)
        let favorites = try await reopened.favorites()
        let collected = try await reopened.isCollected("handbook_000004")
        let notes = try await reopened.notes(ref)
        let layout = try await reopened.layout()
        let skillLayout = try await reopened.skillLayout()
        let language = try await reopened.interfaceLanguage()
        XCTAssertEqual(research, ["pt_000001_000001", unknown])
        XCTAssertEqual(trials, ["gt_0123456789abcdef"])
        XCTAssertEqual(favorites.map(\.object), [ref])
        XCTAssertTrue(collected)
        XCTAssertEqual(notes.map(\.id), [noteID])
        XCTAssertEqual(notes.first?.content, "Preserve this note")
        XCTAssertEqual(layout, .list); XCTAssertEqual(skillLayout, .detailed); XCTAssertEqual(language, .english)
        let db = try SQLite(saved.databaseURL, readOnly: true)
        let rows = try db.rows("SELECT value_json FROM settings WHERE setting_key = 'reference_progress.research'")
        XCTAssertEqual(rows.first?.text("value_json"), "[\"pt_000001_000001\",\"pt_999999_999999\"]")
        XCTAssertEqual(try db.rows("PRAGMA user_version").first?.integer("user_version"), 1)
    }
    func testReferenceProgressRejectsInvalidStoredValuesWithoutOverwriting() async throws {
        let saved = try user(temporary())
        try await saved.setReferenceProgress(.research, id: "pt_000001_000001", completed: true)
        try await saved.setReferenceProgress(.trials, id: "gt_0123456789abcdef", completed: true)
        let db = try SQLite(saved.databaseURL, readOnly: false)
        for json in ["{", "null", "{}", "[1]", "[\"Unknown\"]", "[\"gt_0123456789abcdef\"]",
                     "[\"pt_000001_000001\",\"pt_000001_000001\"]", "[\"pt_000001_000001\\n\"]"] {
            try db.execute("UPDATE settings SET value_json = ? WHERE setting_key = 'reference_progress.research'", [.text(json)])
            let before = try db.rows("SELECT * FROM settings ORDER BY setting_key")
            do {
                _ = try await saved.referenceProgress(.research)
                XCTFail("Malformed saved progress must fail on read.")
            } catch { XCTAssertEqual((error as? HandbookError)?.code, "reference_progress_data") }
            do {
                try await saved.setReferenceProgress(.research, id: "pt_000001_000002", completed: true)
                XCTFail("A write must preserve malformed saved progress.")
            } catch { XCTAssertEqual((error as? HandbookError)?.code, "reference_progress_data") }
            XCTAssertEqual(try db.rows("SELECT * FROM settings ORDER BY setting_key"), before)
        }
        let before = try db.rows("SELECT * FROM settings ORDER BY setting_key")
        for kind in [ReferenceCatalogKind.items, .medals, .habitats] {
            do { _ = try await saved.referenceProgress(kind); XCTFail("Only checklist kinds may read marks.") }
            catch { XCTAssertEqual((error as? HandbookError)?.code, "reference_progress_kind") }
            do { try await saved.setReferenceProgress(kind, id: "pt_000001_000001", completed: true); XCTFail("Only checklist kinds may write marks.") }
            catch { XCTAssertEqual((error as? HandbookError)?.code, "reference_progress_kind") }
        }
        for (kind, id) in [(ReferenceCatalogKind.research, "gt_0123456789abcdef"), (.trials, "pt_000001_000001")] {
            do { try await saved.setReferenceProgress(kind, id: id, completed: true); XCTFail("Checklist IDs must match their kind.") }
            catch { XCTAssertEqual((error as? HandbookError)?.code, "reference_progress_id") }
        }
        XCTAssertEqual(try db.rows("SELECT * FROM settings ORDER BY setting_key"), before)
        let trials = try await saved.referenceProgress(.trials)
        XCTAssertEqual(trials, ["gt_0123456789abcdef"])
    }
    func testAttackCoverageUsesFrozenFireResultsAndChartOrder() async throws {
        let result = try await AssetRepository(assetRoot: assets).attackCoverage(for: ["\u{706b}\u{7cfb}"])
        XCTAssertEqual(result.availableTypes, [
            "\u{666e}\u{901a}", "\u{8349}", "\u{706b}", "\u{6c34}", "\u{5149}", "\u{5730}",
            "\u{51b0}", "\u{9f99}", "\u{7535}", "\u{6bd2}", "\u{866b}", "\u{6b66}",
            "\u{7ffc}", "\u{840c}", "\u{5e7d}", "\u{6076}", "\u{673a}\u{68b0}", "\u{5e7b}",
        ])
        XCTAssertEqual(result.selectedTypes, ["\u{706b}"])
        XCTAssertEqual(result.covered, ["\u{8349}", "\u{51b0}", "\u{866b}", "\u{673a}\u{68b0}"])
        XCTAssertEqual(result.resisted, ["\u{6c34}", "\u{5730}", "\u{9f99}"])
        XCTAssertEqual(result.neutral, [
            "\u{666e}\u{901a}", "\u{706b}", "\u{5149}", "\u{7535}", "\u{6bd2}", "\u{6b66}",
            "\u{7ffc}", "\u{840c}", "\u{5e7d}", "\u{6076}", "\u{5e7b}",
        ])
        XCTAssertEqual(result.source.name, "Module:TypeRelation")
        XCTAssertEqual(result.source.url, "https://wiki.biligame.com/rocom/index.php?title=Module%3ATypeRelation&oldid=39538")
        XCTAssertEqual(result.source.frozenAt, "2026-06-08T19:57:39Z")
    }
    func testAttackCoverageCombinesStrongUnionAndResistedIntersection() async throws {
        let result = try await AssetRepository(assetRoot: assets).attackCoverage(for: ["\u{6c34}", "\u{706b}"])
        XCTAssertEqual(result.selectedTypes, ["\u{706b}", "\u{6c34}"])
        XCTAssertEqual(result.covered, ["\u{8349}", "\u{706b}", "\u{5730}", "\u{51b0}", "\u{866b}", "\u{673a}\u{68b0}"])
        XCTAssertEqual(result.resisted, ["\u{9f99}"])
        XCTAssertEqual(result.neutral, [
            "\u{666e}\u{901a}", "\u{6c34}", "\u{5149}", "\u{7535}", "\u{6bd2}", "\u{6b66}",
            "\u{7ffc}", "\u{840c}", "\u{5e7d}", "\u{6076}", "\u{5e7b}",
        ])
        XCTAssertTrue(Set(result.covered).isDisjoint(with: result.resisted))
        XCTAssertTrue(Set(result.covered + result.resisted).isDisjoint(with: result.neutral))
        XCTAssertEqual(Set(result.covered + result.resisted + result.neutral), Set(result.availableTypes))
    }
    func testAttackCoverageEmptySelectionAndInputValidation() async throws {
        let repository = AssetRepository(assetRoot: assets)
        let empty = try await repository.attackCoverage(for: [])
        XCTAssertEqual(empty.availableTypes.count, 18)
        XCTAssertFalse(empty.availableTypes.contains("\u{65e0}\u{7cfb}\u{522b}"))
        XCTAssertTrue(empty.selectedTypes.isEmpty && empty.covered.isEmpty && empty.resisted.isEmpty && empty.neutral.isEmpty)
        let five = ["\u{706b}", "\u{6c34}", "\u{8349}", "\u{5149}", "\u{5730}"]
        let maximum = try await repository.attackCoverage(for: five)
        XCTAssertEqual(maximum.selectedTypes.count, 5)
        for invalid in [[""], ["Unknown"], ["\u{65e0}\u{7cfb}\u{522b}"], ["\u{706b}", "\u{706b}"],
                        ["\u{706b}", "\u{706b}\u{7cfb}"], five + ["\u{51b0}"]] {
            do {
                _ = try await repository.attackCoverage(for: invalid)
                XCTFail("Unknown, placeholder, duplicate, and over-limit selections must fail.")
            } catch { XCTAssertEqual((error as? HandbookError)?.code, "type_contract") }
        }
    }
    func testAttackCoverageRejectsMalformedFrozenContracts() async throws {
        let data = try Data(contentsOf: assets.appendingPathComponent("wiki/type-relations-v1.json"))
        let original = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let order = original["type_order"] as! [String]
        func changed(_ change: (inout [String: Any]) -> Void) -> [String: Any] {
            var value = original
            change(&value)
            return value
        }
        func relationship(_ field: String, _ values: [String]) -> [String: Any] {
            changed { value in
                var relations = value["relations"] as! [String: [String: Any]]
                relations["\u{6c34}"]?[field] = values
                value["relations"] = relations
            }
        }
        let invalid = [
            changed { $0["contract_version"] = 2 },
            changed { $0["dataset_id"] = "unknown" },
            changed { $0["type_order"] = [String]() },
            changed { $0["type_order"] = order + ["\u{706b}"] },
            changed { value in
                var relations = value["relations"] as! [String: [String: Any]]
                relations.removeValue(forKey: "\u{6c34}")
                value["relations"] = relations
            },
            relationship("strong_against", ["Unknown"]),
            relationship("strong_against", ["\u{5730}", "\u{5730}"]),
            relationship("resisted_by", ["\u{9f99}", "\u{9f99}"]),
            relationship("strong_against", ["\u{8349}"]),
        ]
        for value in invalid {
            let repository = try typeFixture(value)
            do {
                _ = try await repository.attackCoverage(for: ["\u{706b}"])
                XCTFail("Invalid chart identity, references, duplicates, or overlapping relationships must fail.")
            } catch { XCTAssertEqual((error as? HandbookError)?.code, "type_contract") }
        }
    }
    func testAttackCoverageRequiresCompleteKnownTypeSet() async throws {
        let data = try Data(contentsOf: assets.appendingPathComponent("wiki/type-relations-v1.json"))
        let original = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let order = original["type_order"] as! [String]
        let relations = original["relations"] as! [String: [String: Any]]
        for (removed, replacement) in [("\u{6c34}", nil), ("\u{6c34}", "Unknown"),
                                       ("\u{65e0}\u{7cfb}\u{522b}", nil)] as [(String, String?)] {
            func remap(_ name: String) -> String? { name == removed ? replacement : name }
            var value = original
            value["type_order"] = order.compactMap(remap)
            var changed: [String: [String: Any]] = [:]
            for (name, relation) in relations {
                guard let name = remap(name) else { continue }
                var relation = relation
                for field in ["strong_against", "resisted_by", "weak_to", "resists"] {
                    relation[field] = (relation[field] as! [String]).compactMap(remap)
                }
                changed[name] = relation
            }
            value["relations"] = changed
            let repository = try typeFixture(value)
            let legacy = try await repository.relationships(for: ["\u{706b}"])
            XCTAssertEqual(legacy.outgoing.map(\.name), ["\u{706b}"])
            do {
                _ = try await repository.attackCoverage(for: ["\u{706b}"])
                XCTFail("Coverage must require the complete known type set and the no-type placeholder.")
            } catch { XCTAssertEqual((error as? HandbookError)?.code, "type_contract") }
        }
    }
    func testAttackCoverageValidatesSourceWithoutChangingRelationshipQueries() async throws {
        let data = try Data(contentsOf: assets.appendingPathComponent("wiki/type-relations-v1.json"))
        let original = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let originalSource = original["source"] as! [String: Any]
        var invalid: [[String: Any]] = []
        for (field, value) in [("page_id", 1), ("revision_id", 0), ("title", "Other module"),
                               ("revised_at_utc", "invalid"), ("source_sha1", "invalid")] as [(String, Any)] {
            var source = originalSource
            source[field] = value
            invalid.append(source)
        }
        let urls = [
            "http://wiki.biligame.com/rocom/index.php?title=Module%3ATypeRelation&oldid=39538",
            "https://example.test/rocom/index.php?title=Module%3ATypeRelation&oldid=39538",
            "https://wiki.biligame.com/rocom/index.php?title=Other&oldid=39538",
            "https://wiki.biligame.com/rocom/index.php?title=Module%3ATypeRelation&oldid=1",
            "https://wiki.biligame.com/other?title=Module%3ATypeRelation&oldid=39538",
        ]
        for url in urls {
            var source = originalSource
            source["source_url"] = url
            invalid.append(source)
        }
        for source in invalid + [[:], ["revision_id": "invalid"]] {
            var value = original
            value["source"] = source
            let repository = try typeFixture(value)
            let relationships = try await repository.relationships(for: ["\u{706b}"])
            XCTAssertEqual(relationships.outgoing.count, 1)
            do {
                _ = try await repository.attackCoverage(for: ["\u{706b}"])
                XCTFail("Coverage must require valid source identity, revision, hash, timestamp, and URL.")
            } catch { XCTAssertEqual((error as? HandbookError)?.code, "type_contract") }
        }
    }
    func testAssetPathsCannotEscapeBundle() throws {
        XCTAssertNil(CatalogAssets.pet("../catalog/catalog"))
        XCTAssertThrowsError(try AssetRepository.toolImage("activities/icons/../../secret.png", prefix: "activities/icons/"))
        XCTAssertThrowsError(try AssetRepository.toolImage("https://example.test/image.png", prefix: "activities/icons/"))
    }
    func testManifestRejectsEmptyCoverageAndUnknownFields() throws {
        let data = try Data(contentsOf: assets.appendingPathComponent("catalog/bundled_catalog.json"))
        var value = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        value["unexpected"] = true
        XCTAssertThrowsError(try CatalogManifest(data: JSONSerialization.data(withJSONObject: value)))
        value.removeValue(forKey: "unexpected")
        value["coverage"] = [:]
        XCTAssertThrowsError(try CatalogManifest(data: JSONSerialization.data(withJSONObject: value)))
        XCTAssertThrowsError(try CatalogManifest(data: Data()))
    }
    func testAllCurrentImagesResolveThroughNativeDomainHelpers() async throws {
        var query = PetQuery(); query.limit = 200
        while true {
            let pets = try await catalog.searchPets(query)
            for pet in pets {
                let path = try XCTUnwrap(CatalogAssets.pet(pet.illustrationKey))
                XCTAssertTrue(FileManager.default.fileExists(atPath: assets.appendingPathComponent(path).path))
                if pet.hasShiny {
                    let shiny = try XCTUnwrap(CatalogAssets.pet(pet.illustrationKey, shiny: true))
                    XCTAssertTrue(FileManager.default.fileExists(atPath: assets.appendingPathComponent(shiny).path))
                }
                for type in pet.types {
                    let path = try XCTUnwrap(CatalogAssets.type(type))
                    XCTAssertTrue(FileManager.default.fileExists(atPath: assets.appendingPathComponent(path).path))
                }
            }
            if pets.count < query.limit { break }; query.offset += pets.count
        }
        var skills = SkillQuery(); skills.filter = .all; skills.limit = 200
        while true {
            let page = try await catalog.searchSkills(skills)
            for skill in page {
                let path = try XCTUnwrap(CatalogAssets.skill(skill))
                XCTAssertTrue(FileManager.default.fileExists(atPath: assets.appendingPathComponent(path).path))
            }
            if page.count < skills.limit { break }; skills.offset += page.count
        }
    }
    func testNewerCatalogRetentionAndRemoteReplayFloorSurviveRestore() async throws {
        let support = try temporary()
        let bundle = try CatalogBundle.load(assetRoot: assets)
        let installer = CatalogInstaller(supportURL: support)
        _ = try await installer.prepare(bundle)
        let candidateFile = support.appendingPathComponent("owned-candidate.db")
        try bundle.database.write(to: candidateFile)
        do {
            let db = try SQLite(candidateFile, readOnly: false)
            try db.execute("UPDATE catalog_meta SET data_version = 4, snapshot_id = ?", [.text("snapshot-owned-native-test-v4")])
        }
        let bytes = try Data(contentsOf: candidateFile)
        var manifest = try JSONSerialization.jsonObject(with: Data(contentsOf: assets.appendingPathComponent("catalog/bundled_catalog.json"))) as! [String: Any]
        manifest["data_version"] = 4; manifest["snapshot_id"] = "snapshot-owned-native-test-v4"
        manifest["database_sha256"] = sha256(bytes); manifest["database_bytes"] = bytes.count
        let next = try CatalogBundle(manifest: JSONSerialization.data(withJSONObject: manifest), database: bytes, attribution: bundle.attribution)
        let installed = try await installer.installRemote(next, sequence: 3)
        XCTAssertEqual(installed.manifest.dataVersion, 4)
        let reused = try await installer.prepare(bundle)
        XCTAssertEqual(reused.manifest.dataVersion, 4)
        _ = try await installer.prepare(bundle, restore: true)
        let floor = try await installer.highestSequence()
        XCTAssertEqual(floor, 3)
        do { _ = try await installer.installRemote(next, sequence: 3); XCTFail("A replay must fail after restore") } catch {}
        let previous = support.appendingPathComponent("catalog-state/previous_catalog.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: previous.path))
    }
    func testMissingCatalogObjectRetainsSnapshotAndNotes() async throws {
        let repository = try user(temporary())
        let ref = ObjectRef(type: .pet, objectID: "pet_owned_missing_fixture", name: "Saved name snapshot")
        try await repository.setFavorite(ref, enabled: true)
        _ = try await repository.saveNote(ref, content: "Retain this content")
        do { _ = try await catalog.petDetail(ref.objectID); XCTFail("The Catalog object should be absent") } catch {}
        let favorites = try await repository.favorites()
        let notes = try await repository.notes(ref)
        XCTAssertEqual(favorites.first?.object.name, ref.name)
        XCTAssertEqual(notes.first?.content, "Retain this content")
    }
}
