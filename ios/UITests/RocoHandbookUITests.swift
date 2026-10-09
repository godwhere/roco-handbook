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
        XCTAssertTrue(app.buttons["detail.section.Base stats"].exists)
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
        app.buttons["detail.section.My library"].tap()
        let addNote = app.buttons["personal.addNote"]
        XCTAssertTrue(addNote.waitForExistence(timeout: 10)); addNote.tap()
        let editor = app.textViews["note.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10)); editor.tap(); editor.typeText("Native migration UI test note")
        app.buttons["note.save"].tap()
        XCTAssertTrue(app.staticTexts["Native migration UI test note"].waitForExistence(timeout: 10))
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
        app.buttons["detail.section.My library"].tap()
        XCTAssertTrue(app.staticTexts["Native migration UI test note"].waitForExistence(timeout: 10))
        app.terminate(); app.launch()
        XCTAssertTrue(app.textFields["pets.search"].waitForExistence(timeout: 30))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.segmentedControls["settings.layout"].buttons["List"].isSelected)
    }
}
