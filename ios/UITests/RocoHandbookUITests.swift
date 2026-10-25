import XCTest

final class RocoHandbookUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        return app
    }
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<10 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }
    private func revealTowardTop(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<10 {
            if element.isHittable { return }
            app.swipeDown()
        }
        XCTAssertTrue(element.isHittable)
    }
    private func followSystemLanguage(in app: XCUIApplication) {
        app.tabBars.buttons.element(boundBy: 3).tap()
        let language = app.buttons["settings.language"]
        XCTAssertTrue(language.waitForExistence(timeout: 10))
        reveal(language, in: app); language.tap()
        let titles = ["Follow System", "\u{8ddf}\u{968f}\u{7cfb}\u{7edf}"]
        let option = app.buttons.matching(NSPredicate(format: "label IN %@", titles)).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 10)); option.tap()
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value IN %@", titles), object: language)
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 10), .completed)
        app.tabBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
    }
    func testOfflineCatalogSearchAndDetailNavigation() {
        let app = launch()
        let search = app.textFields["pets.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap(); search.typeText("4")
        let pet = app.buttons["pet.pet_000007"]
        XCTAssertTrue(pet.waitForExistence(timeout: 10))
        pet.tap()
        XCTAssertTrue(app.buttons["personal.favorite"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["detail.tab.Overview"].exists)
    }
    func testRefreshedCreatureIsReachableFromBundledCatalog() {
        let app = launch()
        let search = app.textFields["pets.search"]
        search.tap(); search.typeText("467")
        let pet = app.buttons["pet.pet_000620"]
        XCTAssertTrue(pet.waitForExistence(timeout: 10)); pet.tap()
        XCTAssertTrue(app.buttons["detail.tab.Overview"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["\u{4e91}\u{68a6}\u{8c5a}"].firstMatch.exists)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "phase10-new-creature"
        capture.lifetime = .keepAlways
        add(capture)
    }
    func testChineseToolsAndSettingsCaptures() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons.element(boundBy: 2).tap()
        let season = app.buttons["tools.seasons"]
        let features = app.buttons["tools.features"]
        let eggs = app.buttons["tools.eggGroups"]
        // Allow subpixel rounding without relaxing the 44-point target contract.
        for card in [season, features, eggs] {
            XCTAssertTrue(card.waitForExistence(timeout: 10))
            XCTAssertTrue(card.isHittable)
            XCTAssertGreaterThanOrEqual(card.frame.width + 0.001, 44)
            XCTAssertGreaterThanOrEqual(card.frame.height + 0.001, 44)
        }
        XCTAssertGreaterThan(season.frame.height, features.frame.height * 1.5)
        XCTAssertEqual(season.frame.minY, features.frame.minY, accuracy: 2)
        XCTAssertEqual(features.frame.minX, eggs.frame.minX, accuracy: 2)
        XCTAssertLessThanOrEqual(season.frame.maxX, features.frame.minX)
        XCTAssertLessThanOrEqual(season.frame.maxX, eggs.frame.minX)
        XCTAssertLessThanOrEqual(features.frame.maxY, eggs.frame.minY)
        XCTAssertGreaterThanOrEqual(season.frame.maxY + 2, eggs.frame.maxY)
        capture(app, name: "tools-zh")
        for id in ["tools.coverage", "tools.descriptions", "tools.activities", "tools.outfits", "tools.library"] {
            let card = app.buttons[id]
            reveal(card, in: app)
            XCTAssertGreaterThanOrEqual(card.frame.width + 0.001, 44)
            XCTAssertGreaterThanOrEqual(card.frame.height + 0.001, 44)
        }
        capture(app, name: "tools-lower-zh")
        app.tabBars.buttons.element(boundBy: 3).tap()
        for id in ["settings.layout", "settings.skillLayout"] {
            let picker = app.segmentedControls[id]
            XCTAssertTrue(picker.waitForExistence(timeout: 10))
            XCTAssertTrue(picker.isHittable)
        }
        capture(app, name: "settings-zh")
        for id in ["settings.library", "settings.catalogInfo", "settings.checkUpdates", "settings.restore", "settings.licenses"] {
            let action = app.buttons[id]
            reveal(action, in: app)
            XCTAssertGreaterThanOrEqual(action.frame.width + 0.001, 44)
            XCTAssertGreaterThanOrEqual(action.frame.height + 0.001, 44)
        }
        capture(app, name: "settings-lower-zh")
    }
    func testAttackCoverageSelectionLimitResetAndChineseCapture() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        followSystemLanguage(in: app)
        app.tabBars.buttons.element(boundBy: 2).tap()
        let entry = app.buttons["tools.coverage"]
        reveal(entry, in: app); entry.tap()
        XCTAssertTrue(app.navigationBars["\u{6253}\u{51fb}\u{9762}"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["coverage.empty"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["coverage.covered.count"].exists)
        let fire = app.buttons["coverage.type.\u{706b}"]
        XCTAssertTrue(fire.waitForExistence(timeout: 10)); fire.tap()
        XCTAssertTrue(fire.isSelected)
        let covered = app.staticTexts["coverage.covered.count"]
        let resisted = app.staticTexts["coverage.resisted.count"]
        XCTAssertTrue(covered.waitForExistence(timeout: 10))
        XCTAssertTrue(covered.label.hasSuffix(" · 4"))
        XCTAssertTrue(resisted.waitForExistence(timeout: 10))
        XCTAssertTrue(resisted.label.hasSuffix(" · 3"))
        let additionalTypes = ["\u{666e}\u{901a}", "\u{8349}", "\u{6c34}", "\u{5149}"]
        for type in additionalTypes {
            let choice = app.buttons["coverage.type.\(type)"]
            XCTAssertTrue(choice.isEnabled); choice.tap()
            XCTAssertTrue(choice.isSelected)
        }
        XCTAssertTrue(app.staticTexts["coverage.selection.count"].label.hasSuffix("5 / 5"))
        XCTAssertTrue(app.staticTexts["coverage.limit"].exists)
        let ground = app.buttons["coverage.type.\u{5730}"]
        XCTAssertFalse(ground.isEnabled)
        XCTAssertTrue(fire.isEnabled)
        let water = app.buttons["coverage.type.\u{6c34}"]
        water.tap()
        XCTAssertFalse(water.isSelected)
        XCTAssertTrue(ground.isEnabled); ground.tap()
        XCTAssertTrue(ground.isSelected)
        XCTAssertTrue(app.staticTexts["coverage.selection.count"].label.hasSuffix("5 / 5"))
        let reset = app.buttons["coverage.reset"]
        reset.tap()
        XCTAssertTrue(app.staticTexts["coverage.empty"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["coverage.selection.count"].label.hasSuffix("0 / 5"))
        XCTAssertFalse(reset.isEnabled)
        XCTAssertFalse(fire.isSelected)
        XCTAssertFalse(ground.isSelected)
        XCTAssertTrue(water.isEnabled)
        XCTAssertFalse(covered.exists)
        fire.tap()
        XCTAssertTrue(covered.waitForExistence(timeout: 10))
        reveal(resisted, in: app)
        capture(app, name: "coverage-fire-zh")
        let source = app.buttons["tools.coverage.sources"]
        revealTowardTop(source, in: app)
        XCTAssertGreaterThanOrEqual(source.frame.width + 0.001, 44)
        XCTAssertGreaterThanOrEqual(source.frame.height + 0.001, 44)
        source.tap()
        XCTAssertTrue(app.staticTexts["coverage.source.name"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["coverage.source.name"].label, "Module:TypeRelation")
        let sourceURL = app.staticTexts["coverage.source.url"].label
        XCTAssertTrue(sourceURL.contains("title=Module%3ATypeRelation"))
        XCTAssertTrue(sourceURL.contains("oldid="))
        XCTAssertTrue(app.staticTexts["coverage.source.date"].exists)
        capture(app, name: "coverage-source-zh")
        app.buttons["coverage.source.done"].tap()
        XCTAssertTrue(app.navigationBars["\u{6253}\u{51fb}\u{9762}"].waitForExistence(timeout: 10))
    }
    func testInterfaceLanguageSwitchPersistsAcrossRestartAndCatalogRestore() {
        let app = launch()
        let simplifiedChinese = "\u{7b80}\u{4f53}\u{4e2d}\u{6587}"
        let chineseSettings = "\u{8bbe}\u{7f6e}"
        let settingsTab = app.tabBars.buttons.element(boundBy: 3)
        settingsTab.tap()
        let language = app.buttons["settings.language"]
        XCTAssertTrue(language.waitForExistence(timeout: 10))
        reveal(language, in: app)
        language.tap()
        let englishOption = app.buttons["English"]
        XCTAssertTrue(englishOption.waitForExistence(timeout: 10))
        englishOption.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["Settings"].isSelected)
        XCTAssertEqual(language.label, "Language")
        XCTAssertEqual(language.value as? String, "English")
        capture(app, name: "language-english")

        language.tap()
        let chineseOption = app.buttons[simplifiedChinese]
        XCTAssertTrue(chineseOption.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Follow System"].exists)
        XCTAssertTrue(englishOption.exists)
        capture(app, name: "language-menu")
        chineseOption.tap()
        XCTAssertTrue(app.navigationBars[chineseSettings].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons[chineseSettings].isSelected)
        XCTAssertTrue(app.tabBars.buttons["\u{5de5}\u{5177}"].exists)
        XCTAssertEqual(language.value as? String, simplifiedChinese)
        let skillLayout = app.segmentedControls["settings.skillLayout"]
        XCTAssertTrue(skillLayout.buttons["\u{53cc}\u{5217}"].exists)
        XCTAssertTrue(skillLayout.buttons["\u{4e09}\u{5217}"].exists)
        XCTAssertTrue(skillLayout.buttons["\u{8be6}\u{7ec6}\u{63cf}\u{8ff0}"].exists)
        language.tap()
        XCTAssertTrue(app.buttons["\u{8ddf}\u{968f}\u{7cfb}\u{7edf}"].waitForExistence(timeout: 10))
        app.navigationBars[chineseSettings].tap()
        capture(app, name: "language-chinese")

        // The saved App language takes precedence over the unchanged English launch locale.
        app.terminate(); app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.tabBars.buttons[chineseSettings].exists)
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars[chineseSettings].waitForExistence(timeout: 10))
        XCTAssertTrue(language.waitForExistence(timeout: 10))
        XCTAssertEqual(language.value as? String, simplifiedChinese)
        let restore = app.buttons["settings.restore"]
        reveal(restore, in: app)
        restore.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 10))
        app.alerts.buttons["\u{6062}\u{590d}\u{56fe}\u{9274}"].tap()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.tabBars.buttons.element(boundBy: 0).isSelected)
        XCTAssertTrue(app.tabBars.buttons[chineseSettings].exists)
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars[chineseSettings].waitForExistence(timeout: 10))
        reveal(language, in: app)
        XCTAssertEqual(language.value as? String, simplifiedChinese)

        language.tap()
        let systemOption = app.buttons["\u{8ddf}\u{968f}\u{7cfb}\u{7edf}"]
        XCTAssertTrue(systemOption.waitForExistence(timeout: 10))
        systemOption.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["Settings"].isSelected)
        XCTAssertTrue(app.tabBars.buttons["Tools"].exists)
        XCTAssertEqual(language.label, "Language")
        XCTAssertEqual(language.value as? String, "Follow System")
        XCTAssertTrue(skillLayout.buttons["Two columns"].exists)
        XCTAssertTrue(skillLayout.buttons["Detailed"].exists)
    }
    func testToolsAndSettingsRemainReachableWithAccessibilityText() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN",
                               "-UIPreferredContentSizeCategoryName",
                               "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        followSystemLanguage(in: app)
        app.tabBars.buttons.element(boundBy: 2).tap()
        let first = app.buttons["tools.seasons"]
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(first.frame.height + 0.001, 44)
        capture(app, name: "tools-large-text-zh")
        let coverage = app.buttons["tools.coverage"]
        reveal(coverage, in: app); coverage.tap()
        let fire = app.buttons["coverage.type.\u{706b}"]
        XCTAssertTrue(fire.waitForExistence(timeout: 10))
        reveal(fire, in: app)
        XCTAssertGreaterThanOrEqual(fire.frame.width + 0.001, 44)
        XCTAssertGreaterThanOrEqual(fire.frame.height + 0.001, 44)
        XCTAssertLessThanOrEqual(fire.frame.maxX, app.frame.maxX)
        fire.tap()
        let covered = app.staticTexts["coverage.covered.count"]
        reveal(covered, in: app)
        XCTAssertTrue(covered.label.hasSuffix(" · 4"))
        capture(app, name: "coverage-large-text-zh")
        let source = app.buttons["tools.coverage.sources"]
        revealTowardTop(source, in: app)
        XCTAssertGreaterThanOrEqual(source.frame.width + 0.001, 44)
        XCTAssertGreaterThanOrEqual(source.frame.height + 0.001, 44)
        XCTAssertLessThanOrEqual(app.staticTexts["coverage.selection.count"].frame.maxY, source.frame.minY)
        XCTAssertLessThanOrEqual(app.buttons["coverage.reset"].frame.maxX, source.frame.minX)
        source.tap()
        XCTAssertTrue(app.staticTexts["coverage.source.name"].waitForExistence(timeout: 10))
        app.buttons["coverage.source.done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        reveal(app.buttons["tools.library"], in: app)
        app.tabBars.buttons.element(boundBy: 3).tap()
        let language = app.buttons["settings.language"]
        XCTAssertTrue(language.waitForExistence(timeout: 10))
        reveal(language, in: app)
        XCTAssertGreaterThanOrEqual(language.frame.width + 0.001, 44)
        XCTAssertGreaterThanOrEqual(language.frame.height + 0.001, 44)
        let layout = app.buttons["settings.layout"]
        reveal(layout, in: app)
        XCTAssertTrue(layout.exists)
        XCTAssertFalse(app.segmentedControls["settings.layout"].exists)
        capture(app, name: "settings-large-text-zh")
        let restore = app.buttons["settings.restore"]
        reveal(restore, in: app)
        XCTAssertGreaterThanOrEqual(restore.frame.height + 0.001, 44)
        restore.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 10))
        app.alerts.buttons["\u{53d6}\u{6d88}"].tap()
        reveal(app.buttons["settings.licenses"], in: app)
        capture(app, name: "settings-large-text-lower-zh")
    }
    func testCatalogToolbarAndThreeColumnGeometryAndPersistence() {
        let app = launch()
        let sort = app.buttons["pets.sort"], filters = app.buttons["pets.filters"], search = app.textFields["pets.search"]
        XCTAssertEqual(sort.frame.midY, filters.frame.midY, accuracy: 2)
        XCTAssertEqual(sort.frame.midY, search.frame.midY, accuracy: 2)
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "pet.pet_"))
        XCTAssertTrue(cards.element(boundBy: 2).waitForExistence(timeout: 10))
        let first = cards.element(boundBy: 0).frame
        for index in 1...2 {
            let frame = cards.element(boundBy: index).frame
            XCTAssertEqual(first.minY, frame.minY, accuracy: 2)
            XCTAssertGreaterThan(frame.minX, first.minX)
            XCTAssertLessThanOrEqual(frame.maxX, app.frame.maxX)
        }
        sort.tap()
        app.buttons["Name"].tap()
        filters.tap()
        XCTAssertTrue(app.navigationBars["Filters"].waitForExistence(timeout: 10))
        app.buttons["Done"].tap()
        app.tabBars.buttons["Settings"].tap()
        let layout = app.segmentedControls["settings.layout"]
        XCTAssertTrue(layout.buttons["Three columns"].isSelected)
        layout.buttons["Two columns"].tap()
        app.tabBars.buttons["Creatures"].tap()
        XCTAssertTrue(cards.element(boundBy: 2).waitForExistence(timeout: 10))
        XCTAssertGreaterThan(cards.element(boundBy: 2).frame.minY, cards.element(boundBy: 0).frame.minY)
        app.tabBars.buttons["Settings"].tap()
        layout.buttons["Three columns"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(layout.buttons["Three columns"].isSelected)
    }
    func testCreatureDetailTabsSkillSearchAndEggGroupNavigation() {
        let app = launch()
        let pet = app.buttons["pet.pet_000001"]
        XCTAssertTrue(pet.waitForExistence(timeout: 10)); pet.tap()
        XCTAssertTrue(app.buttons["detail.tab.Overview"].waitForExistence(timeout: 10))
        app.buttons["detail.tab.Skills"].tap()
        let search = app.textFields["detail.skills.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "detail.skill.native:")).firstMatch.exists)
        search.tap(); search.typeText("zzzz-no-skill")
        XCTAssertTrue(app.staticTexts["No skills match these filters."].waitForExistence(timeout: 10))
        app.buttons["Clear search"].tap()
        app.buttons["detail.skills.filters"].tap()
        let physical = app.buttons["filter.Skill type.\u{7269}\u{653b}"]
        XCTAssertTrue(physical.waitForExistence(timeout: 10)); physical.tap()
        app.buttons["filter.Types.\u{666e}\u{901a}\u{7cfb}"].tap()
        app.buttons["Done"].tap()
        XCTAssertEqual(app.keyboards.count, 0)
        let scratches = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND identifier ENDSWITH %@", "detail.skill.native:", ":skill_000246")).firstMatch
        let rest = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND identifier ENDSWITH %@", "detail.skill.native:", ":skill_000273")).firstMatch
        XCTAssertTrue(scratches.waitForExistence(timeout: 10))
        XCTAssertTrue(scratches.isHittable)
        XCTAssertTrue(waitForAbsence(rest))
        app.buttons["detail.skills.filters"].tap()
        XCTAssertTrue(physical.isSelected)
        app.buttons["filters.reset"].tap()
        app.buttons["Done"].tap()
        app.buttons["detail.skills.Bloodline effects"].tap()
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "detail.skill.native:")).firstMatch.exists)
        app.buttons["detail.tab.Type relationships"].tap()
        let direction = app.segmentedControls["detail.types.direction"]
        XCTAssertTrue(direction.waitForExistence(timeout: 10))
        XCTAssertTrue(direction.buttons["Attacking"].isSelected)
        direction.buttons["Defending"].tap()
        XCTAssertTrue(direction.buttons["Defending"].isSelected)
        app.buttons["detail.tab.Egg groups tab"].tap()
        let group = app.buttons["detail.eggGroup.6"]
        XCTAssertTrue(group.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["detail.eggGroup.9"].exists)
        group.tap()
        XCTAssertTrue(app.navigationBars["Egg groups"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["pet.pet_000001"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        for destination in ["Source", "Evolution"] {
            app.buttons["detail.more"].tap(); app.buttons["detail.section.\(destination)"].tap()
            XCTAssertTrue(app.navigationBars[destination].waitForExistence(timeout: 10))
            app.buttons["Done"].tap()
        }
    }
    func testExpandedArtworkContractsAndRestoresWithoutLosingShinySelection() {
        let app = launch()
        let search = app.textFields["pets.search"]
        search.tap(); search.typeText("021")
        let pet = app.buttons["pet.pet_000131"]
        XCTAssertTrue(pet.waitForExistence(timeout: 10)); pet.tap()
        let art = app.descendants(matching: .any).matching(identifier: "detail.illustration").firstMatch
        XCTAssertTrue(art.waitForExistence(timeout: 10))
        let expandedWidth = art.frame.width
        XCTAssertGreaterThan(expandedWidth, 220)
        let variants = app.segmentedControls["detail.shiny"]
        variants.buttons["Shiny"].tap()
        app.swipeUp()
        XCTAssertTrue(waitForValue("Compact illustration", on: art))
        XCTAssertLessThan(art.frame.width, expandedWidth * 0.6)
        XCTAssertTrue(variants.buttons["Shiny"].isSelected)
        XCTAssertTrue(app.buttons["detail.tab.Overview"].isHittable)
        app.buttons["detail.tab.Egg groups tab"].tap()
        XCTAssertTrue(app.buttons["detail.tab.Skills"].isHittable)
        app.swipeDown()
        XCTAssertTrue(waitForValue("Expanded illustration", on: art))
        XCTAssertEqual(art.frame.width, expandedWidth, accuracy: 2)
        XCTAssertTrue(variants.buttons["Shiny"].isSelected)
        variants.buttons["Original"].tap()
    }
    func testAdaptiveCreatureAndSkillFiltersApplyAndReset() {
        let app = launch()
        app.buttons["pets.filters"].tap()
        let light = app.buttons["filter.Types.type_91d4989e61e2"]
        let ice = app.buttons["filter.Types.type_59512ce7619f"]
        let grass = app.buttons["filter.Types.type_d6013fab5504"]
        XCTAssertTrue(light.waitForExistence(timeout: 10))
        XCTAssertEqual(light.frame.minY, ice.frame.minY, accuracy: 2)
        XCTAssertGreaterThan(ice.frame.minX, light.frame.minX)
        XCTAssertGreaterThanOrEqual(light.frame.height, 44)
        light.tap(); grass.tap()
        XCTAssertTrue(light.isSelected && grass.isSelected)
        let first = app.buttons["filter.Stage.1"], third = app.buttons["filter.Stage.3"]
        if !third.isHittable { app.swipeUp() }
        XCTAssertEqual(first.frame.minY, third.frame.minY, accuracy: 2)
        first.tap(); third.tap()
        XCTAssertTrue(first.isSelected && third.isSelected)
        first.tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["pet.pet_000007"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["pet.pet_000001"].exists)
        app.buttons["pets.filters"].tap()
        XCTAssertTrue(third.isSelected)
        app.buttons["filters.reset"].tap()
        XCTAssertFalse(light.isSelected || grass.isSelected || third.isSelected)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["pet.pet_000001"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Skills"].tap()
        app.buttons["skills.filters"].tap()
        let physical = app.buttons["filter.Skill type.\u{7269}\u{653b}"]
        let magic = app.buttons["filter.Skill type.\u{9b54}\u{653b}"]
        XCTAssertTrue(physical.waitForExistence(timeout: 10))
        XCTAssertEqual(physical.frame.minY, magic.frame.minY, accuracy: 2)
        physical.tap(); magic.tap()
        XCTAssertTrue(physical.isSelected && magic.isSelected)
        magic.tap()
        app.buttons["filter.Types.type_b7dd19cc3676"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["skill.skill_000678"].waitForExistence(timeout: 10))
        XCTAssertTrue(waitForAbsence(app.buttons["skill.skill_000323"]))
        app.buttons["skills.filters"].tap()
        XCTAssertTrue(physical.isSelected)
        app.buttons["filters.reset"].tap()
        XCTAssertFalse(physical.isSelected || magic.isSelected)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["skill.skill_000323"].waitForExistence(timeout: 10))
    }
    private func waitForValue(_ value: String, on element: XCUIElement) -> Bool {
        XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: element)], timeout: 10) == .completed
    }
    private func waitForAbsence(_ element: XCUIElement) -> Bool {
        XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)], timeout: 10) == .completed
    }
    func testSkillLayoutsPersistAndPreserveDescriptionsAndLearningConditions() {
        let app = launch()
        app.tabBars.buttons["Settings"].tap()
        let preference = app.segmentedControls["settings.skillLayout"]
        XCTAssertTrue(preference.waitForExistence(timeout: 10))
        preference.buttons["Two columns"].tap()
        app.tabBars.buttons["Skills"].tap()
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "skill.skill_"))
        XCTAssertTrue(cards.element(boundBy: 2).waitForExistence(timeout: 10))
        assertColumns(cards, count: 2, in: app)
        let description = "\u{5bf9}\u{654c}\u{65b9}\u{7cbe}\u{7075}\u{9020}\u{6210}\u{7269}\u{7406}\u{4f24}\u{5bb3}\u{3002}"
        XCTAssertFalse(app.buttons["skill.skill_000678"].label.contains(description))
        chooseSkillLayout("Three columns", menu: "skills.layout", in: app)
        assertColumns(cards, count: 3, in: app)
        chooseSkillLayout("Detailed", menu: "skills.layout", in: app)
        XCTAssertGreaterThan(cards.element(boundBy: 0).frame.width, app.frame.width * 0.8)
        XCTAssertTrue(app.buttons["skill.skill_000678"].label.contains(description))
        app.terminate(); app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(preference.buttons["Detailed"].isSelected)
        preference.buttons["Two columns"].tap()
        app.tabBars.buttons["Creatures"].tap()
        app.buttons["pet.pet_000001"].tap()
        XCTAssertTrue(app.buttons["detail.tab.Skills"].waitForExistence(timeout: 10))
        app.buttons["detail.tab.Skills"].tap()
        let learned = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "detail.skill.native:"))
        XCTAssertTrue(learned.element(boundBy: 2).waitForExistence(timeout: 10))
        assertColumns(learned, count: 2, in: app)
        XCTAssertTrue(learned.element(boundBy: 0).label.contains("Level 1"))
        chooseSkillLayout("Three columns", menu: "detail.skills.layout", in: app)
        assertColumns(learned, count: 3, in: app)
        learned.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Creature learning conditions"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Level 1"].exists)
        XCTAssertTrue(app.staticTexts["Source stage 1"].exists)
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(preference.buttons["Three columns"].isSelected)
        preference.buttons["Two columns"].tap()
        app.tabBars.buttons["Tools"].tap()
        app.buttons["tools.features"].tap()
        XCTAssertTrue(cards.element(boundBy: 0).waitForExistence(timeout: 10))
        XCTAssertFalse(cards.element(boundBy: 0).label.contains("Energy"))
        XCTAssertFalse(cards.element(boundBy: 0).label.contains("Power"))
    }
    private func chooseSkillLayout(_ label: String, menu: String, in app: XCUIApplication) {
        app.buttons[menu].tap()
        app.buttons[label].tap()
    }
    private func assertColumns(_ cards: XCUIElementQuery, count: Int, in app: XCUIApplication) {
        let first = cards.element(boundBy: 0).frame
        for index in 0..<count {
            let frame = cards.element(boundBy: index).frame
            XCTAssertEqual(frame.minY, first.minY, accuracy: 2)
            XCTAssertLessThanOrEqual(frame.maxX, app.frame.maxX)
            XCTAssertGreaterThanOrEqual(frame.height, 44)
            if index > 0 { XCTAssertGreaterThan(frame.minX, first.minX) }
        }
        XCTAssertGreaterThan(cards.element(boundBy: count).frame.minY, first.minY)
    }
    func testCenteredCreatureIdentityAndIllustratedSkillUserNavigation() {
        let app = launch()
        app.buttons["pet.pet_000559"].tap()
        assertCenteredIdentity(in: app)
        XCTAssertEqual(app.staticTexts["detail.identity.name"].frame.midX, app.frame.midX, accuracy: 2)
        let art = app.descendants(matching: .any).matching(identifier: "detail.illustration").firstMatch
        app.buttons["detail.tab.Skills"].tap()
        app.swipeUp()
        XCTAssertTrue(waitForValue("Compact illustration", on: art))
        assertCenteredIdentity(in: app)
        XCTAssertGreaterThanOrEqual(art.frame.minY, app.navigationBars["Creature details"].frame.maxY)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["pet.pet_000001"].tap()
        app.buttons["detail.tab.Skills"].tap()
        app.buttons["detail.skill.native:0:skill_000246"].tap()
        let card = app.buttons["skill.user.pet_000007:native:0"]
        for _ in 0..<6 where !card.isHittable { app.swipeUp() }
        XCTAssertTrue(card.isHittable)
        XCTAssertTrue(card.label.contains("NO.004"))
        XCTAssertTrue(card.label.contains("Level 1"))
        XCTAssertTrue(card.label.contains("Source stage 1"))
        card.tap()
        let name = app.staticTexts["detail.identity.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        XCTAssertEqual(name.label, "\u{9b54}\u{529b}\u{732b}")
        assertCenteredIdentity(in: app)
    }
    private func assertCenteredIdentity(in app: XCUIApplication) {
        let name = app.staticTexts["detail.identity.name"]
        let types = app.descendants(matching: .any).matching(identifier: "detail.identity.types").firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        XCTAssertTrue(types.waitForExistence(timeout: 10))
        XCTAssertEqual(name.frame.midX, types.frame.midX, accuracy: 2)
    }
    func testChineseCenteredDetailAndVisualSkillUserCaptures() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons.element(boundBy: 3).tap()
        app.segmentedControls["settings.skillLayout"].buttons.element(boundBy: 0).tap()
        app.tabBars.buttons.element(boundBy: 0).tap()
        app.buttons["pet.pet_000559"].tap()
        assertCenteredIdentity(in: app)
        capture(app, name: "detail-centered-expanded-zh")
        app.buttons["detail.tab.Skills"].tap()
        app.swipeUp()
        let art = app.descendants(matching: .any).matching(identifier: "detail.illustration").firstMatch
        XCTAssertTrue(waitForValue("\u{5c0f}\u{56fe}", on: art))
        assertCenteredIdentity(in: app)
        capture(app, name: "detail-pinned-navigation-zh")
        app.swipeUp()
        capture(app, name: "detail-pinned-deep-scroll-zh")
        app.terminate(); app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.buttons["pet.pet_000001"].tap()
        app.buttons["detail.tab.Skills"].tap()
        app.buttons["detail.skill.native:0:skill_000246"].tap()
        let learner = app.buttons["skill.user.pet_000007:native:0"]
        for _ in 0..<6 where !learner.isHittable { app.swipeUp() }
        XCTAssertTrue(learner.isHittable)
        capture(app, name: "skill-learning-cards-zh")
        app.terminate(); app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons.element(boundBy: 2).tap()
        app.buttons["tools.features"].tap()
        let feature = app.buttons["skill.skill_000211"]
        XCTAssertTrue(feature.waitForExistence(timeout: 10)); feature.tap()
        XCTAssertTrue(app.staticTexts["拥有该特性的精灵"].waitForExistence(timeout: 10))
        let owner = app.buttons["skill.user.pet_000539:feature:0"]
        XCTAssertTrue(owner.waitForExistence(timeout: 10))
        for _ in 0..<4 where !owner.isHittable { app.swipeUp() }
        XCTAssertTrue(owner.isHittable)
        capture(app, name: "skill-feature-cards-zh")
    }
    func testChineseNeutralHeroAndCompactSkillCaptures() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons.element(boundBy: 3).tap()
        app.segmentedControls["settings.layout"].buttons.element(boundBy: 0).tap()
        app.segmentedControls["settings.skillLayout"].buttons.element(boundBy: 0).tap()
        app.tabBars.buttons.element(boundBy: 1).tap()
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "skill.skill_"))
        XCTAssertTrue(cards.element(boundBy: 2).waitForExistence(timeout: 10))
        capture(app, name: "skills-two-columns-zh")
        chooseSkillLayout("\u{4e09}\u{5217}", menu: "skills.layout", in: app)
        capture(app, name: "skills-three-columns-zh")
        chooseSkillLayout("\u{8be6}\u{7ec6}\u{63cf}\u{8ff0}", menu: "skills.layout", in: app)
        capture(app, name: "skills-detailed-zh")
        chooseSkillLayout("\u{53cc}\u{5217}", menu: "skills.layout", in: app)
        app.tabBars.buttons.element(boundBy: 0).tap()
        app.buttons["pet.pet_000004"].tap()
        XCTAssertTrue(app.buttons["detail.tab.Overview"].waitForExistence(timeout: 10))
        capture(app, name: "neutral-hero-expanded-zh")
        app.swipeUp()
        let art = app.descendants(matching: .any).matching(identifier: "detail.illustration").firstMatch
        XCTAssertTrue(waitForValue("\u{5c0f}\u{56fe}", on: art))
        capture(app, name: "neutral-hero-compact-zh")
        app.buttons["detail.tab.Skills"].tap()
        capture(app, name: "creature-skills-two-columns-zh")
        chooseSkillLayout("\u{4e09}\u{5217}", menu: "detail.skills.layout", in: app)
        capture(app, name: "creature-skills-three-columns-zh")
        chooseSkillLayout("\u{8be6}\u{7ec6}\u{63cf}\u{8ff0}", menu: "detail.skills.layout", in: app)
        capture(app, name: "creature-skills-detailed-zh")
        chooseSkillLayout("\u{53cc}\u{5217}", menu: "detail.skills.layout", in: app)
    }
    func testChineseCatalogAndReferenceDetailCaptures() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons.element(boundBy: 3).tap()
        app.segmentedControls["settings.layout"].buttons.element(boundBy: 0).tap()
        app.tabBars.buttons.element(boundBy: 0).tap()
        capture(app, name: "catalog-zh")
        app.buttons["pets.filters"].tap()
        XCTAssertTrue(app.buttons["filters.reset"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["filter.Types.type_91d4989e61e2"].waitForExistence(timeout: 10))
        capture(app, name: "creature-filters-zh")
        app.buttons["\u{5b8c}\u{6210}"].tap()
        app.tabBars.buttons.element(boundBy: 1).tap()
        app.buttons["skills.filters"].tap()
        XCTAssertTrue(app.buttons["filters.reset"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["filter.Types.type_91d4989e61e2"].waitForExistence(timeout: 10))
        capture(app, name: "skill-filters-zh")
        app.buttons["\u{5b8c}\u{6210}"].tap()
        app.tabBars.buttons.element(boundBy: 0).tap()
        let pet = app.buttons["pet.pet_000558"]
        XCTAssertTrue(pet.waitForExistence(timeout: 10)); pet.tap()
        XCTAssertTrue(app.buttons["detail.tab.Overview"].waitForExistence(timeout: 10))
        capture(app, name: "detail-overview-zh")
        app.swipeUp()
        let art = app.descendants(matching: .any).matching(identifier: "detail.illustration").firstMatch
        XCTAssertTrue(waitForValue("\u{5c0f}\u{56fe}", on: art))
        capture(app, name: "detail-compact-zh")
        for (tab, name) in [("Skills", "detail-skills-zh"), ("Type relationships", "detail-types-zh"), ("Egg groups tab", "detail-eggs-zh")] {
            app.buttons["detail.tab.\(tab)"].tap()
            capture(app, name: name)
            if tab == "Skills" {
                app.buttons["detail.skills.filters"].tap()
                XCTAssertTrue(app.buttons["filters.reset"].waitForExistence(timeout: 10))
                capture(app, name: "detail-skill-filters-zh")
                app.buttons["\u{5b8c}\u{6210}"].tap()
            }
        }
    }
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
    func testSourceBackedShinyIllustrationSwitch() {
        let app = launch()
        let search = app.textFields["pets.search"]
        search.tap(); search.typeText("021")
        let pet = app.buttons["pet.pet_000131"]
        XCTAssertTrue(pet.waitForExistence(timeout: 10)); pet.tap()
        let variants = app.segmentedControls["detail.shiny"]
        XCTAssertTrue(variants.waitForExistence(timeout: 10))
        variants.buttons["Shiny"].tap()
        XCTAssertTrue(variants.buttons["Shiny"].isSelected)
        variants.buttons["Original"].tap()
        XCTAssertTrue(variants.buttons["Original"].isSelected)
    }
    func testAllDestinationsAndEightToolRoutes() {
        let app = launch()
        followSystemLanguage(in: app)
        app.tabBars.buttons["Skills"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["skills.catalog"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Tools"].tap()
        let routes = [
            ("tools.seasons", "Season archive"),
            ("tools.features", "Feature handbook"),
            ("tools.eggGroups", "Egg groups"),
            ("tools.coverage", "Attack coverage"),
            ("tools.descriptions", "Game descriptions"),
            ("tools.activities", "Activity timeline"),
            ("tools.outfits", "Outfit inspiration"),
            ("tools.library", "My library"),
        ]
        for (id, title) in routes {
            let link = app.buttons[id]
            reveal(link, in: app)
            XCTAssertTrue(link.waitForExistence(timeout: 10))
            link.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 15))
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["settings.restore"].waitForExistence(timeout: 10))
        reveal(app.buttons["settings.restore"], in: app)
    }
    func testFavoritesNotesLayoutAndRestorePreservePersonalData() {
        let app = launch()
        let pet = app.buttons["pet.pet_000001"]
        XCTAssertTrue(pet.waitForExistence(timeout: 10)); pet.tap()
        let favorite = app.buttons["personal.favorite"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 10))
        if favorite.label == "Add favorite" { favorite.tap() }
        app.buttons["detail.more"].tap(); app.buttons["detail.section.My library"].tap()
        let addNote = app.buttons["personal.addNote"]
        XCTAssertTrue(addNote.waitForExistence(timeout: 10)); addNote.tap()
        let editor = app.textViews["note.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10)); editor.tap(); editor.typeText("Native migration UI test note")
        app.buttons["note.save"].tap()
        XCTAssertTrue(app.staticTexts["Native migration UI test note"].waitForExistence(timeout: 10))
        app.buttons["Done"].tap()
        app.tabBars.buttons["Settings"].tap()
        let layout = app.segmentedControls["settings.layout"]
        XCTAssertTrue(layout.waitForExistence(timeout: 10))
        layout.buttons["List"].tap()
        reveal(app.buttons["settings.restore"], in: app)
        app.buttons["settings.restore"].tap()
        app.alerts.buttons["Restore Catalog"].tap()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons["Tools"].tap()
        reveal(app.buttons["tools.library"], in: app)
        app.buttons["tools.library"].tap()
        let saved = app.buttons["favorite.pet.pet_000001"]
        XCTAssertTrue(saved.waitForExistence(timeout: 10))
        saved.tap()
        app.buttons["detail.more"].tap(); app.buttons["detail.section.My library"].tap()
        XCTAssertTrue(app.staticTexts["Native migration UI test note"].waitForExistence(timeout: 10))
        app.terminate(); app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.segmentedControls["settings.layout"].buttons["List"].isSelected)
    }
}
