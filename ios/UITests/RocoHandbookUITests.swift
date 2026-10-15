import XCTest

final class RocoHandbookUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        return app
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
    func testChineseCatalogAndReferenceDetailCaptures() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons.element(boundBy: 3).tap()
        app.segmentedControls["settings.layout"].buttons.element(boundBy: 0).tap()
        app.tabBars.buttons.element(boundBy: 0).tap()
        capture(app, name: "catalog-zh")
        let pet = app.buttons["pet.pet_000558"]
        XCTAssertTrue(pet.waitForExistence(timeout: 10)); pet.tap()
        XCTAssertTrue(app.buttons["detail.tab.Overview"].waitForExistence(timeout: 10))
        capture(app, name: "detail-overview-zh")
        for (tab, name) in [("Skills", "detail-skills-zh"), ("Type relationships", "detail-types-zh"), ("Egg groups tab", "detail-eggs-zh")] {
            app.buttons["detail.tab.\(tab)"].tap()
            capture(app, name: name)
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
    func testAllDestinationsAndSevenToolRoutes() {
        let app = launch()
        app.tabBars.buttons["Skills"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["skills.catalog"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Tools"].tap()
        let routes = [
            ("tools.seasons", "Season archive"),
            ("tools.features", "Feature handbook"),
            ("tools.eggGroups", "Egg groups"),
            ("tools.descriptions", "Game descriptions"),
            ("tools.activities", "Activity timeline"),
            ("tools.outfits", "Outfit inspiration"),
            ("tools.library", "My library"),
        ]
        for (id, title) in routes {
            let link = app.buttons[id]
            if !link.isHittable { app.swipeUp() }
            XCTAssertTrue(link.waitForExistence(timeout: 10))
            link.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 15))
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["settings.restore"].waitForExistence(timeout: 10))
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
        app.buttons["settings.restore"].tap()
        app.alerts.buttons["Restore Catalog"].tap()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons["Tools"].tap()
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
