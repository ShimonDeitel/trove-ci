import XCTest

final class TroveUITests: XCTestCase {
    private var interruptionMonitorToken: NSObjectProtocol?

    override func setUpWithError() throws {
        continueAfterFailure = false
        interruptionMonitorToken = addUIInterruptionMonitor(withDescription: "System alert dismissal") { alert in
            for label in ["Allow", "OK", "Don't Allow", "Cancel"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        if let token = interruptionMonitorToken {
            removeUIInterruptionMonitor(token)
        }
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testHomeShowsSeedPetOnLaunch() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["petNameLabel_Buddy"].waitForExistence(timeout: 12), "Seed pet did not appear on launch")
    }

    func testTrendDialAppearsForSeedPet() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["petNameLabel_Buddy"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["trendLabel_Buddy"].waitForExistence(timeout: 12), "Trend dial label did not appear")
    }

    func testLogWeightFromHome() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["petNameLabel_Buddy"].waitForExistence(timeout: 12))

        let logButton = app.buttons["logWeightButton_Buddy"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 12))
        logButton.tap()

        let weightField = app.textFields["entryWeightField"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 12))
        weightField.tap()
        weightField.typeText("47.5")

        let saveButton = app.buttons["saveEntryButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 8))
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.buttons["petNameLabel_Buddy"].waitForExistence(timeout: 12), "Home did not reappear after logging weight")
    }

    func testEditPetChangesName() throws {
        let app = launchApp()
        let petLabel = app.buttons["petNameLabel_Buddy"]
        XCTAssertTrue(petLabel.waitForExistence(timeout: 12))
        petLabel.tap()

        let nameField = app.textFields["petNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.press(forDuration: 1.0)
        nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 12))
        nameField.typeText("Charlie")

        app.buttons["savePetButton"].tap()

        XCTAssertTrue(app.buttons["petNameLabel_Charlie"].waitForExistence(timeout: 12), "Pet name did not update")
    }

    func testDeletePetViaForm() throws {
        let app = launchApp()
        let petLabel = app.buttons["petNameLabel_Buddy"]
        XCTAssertTrue(petLabel.waitForExistence(timeout: 12))
        petLabel.tap()

        app.buttons["deletePetButton"].tap()

        XCTAssertFalse(app.buttons["petNameLabel_Buddy"].waitForExistence(timeout: 6), "Pet was not deleted")
    }

    func testFreeLimitTriggersPaywallAtSecondPet() throws {
        let app = launchApp()
        // Seed data already has 1 pet (free limit is 1).
        let addButton = app.buttons["addPetButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()
        XCTAssertTrue(app.staticTexts["Trove Pro"].waitForExistence(timeout: 12), "Paywall did not appear after hitting the free pet limit")
    }

    func testSettingsWeightUnitToggle() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        let unitPicker = app.segmentedControls["weightUnitPicker"]
        XCTAssertTrue(unitPicker.waitForExistence(timeout: 12))
        unitPicker.buttons["kg"].tap()

        XCTAssertTrue(unitPicker.buttons["kg"].isSelected)
    }

    func testSettingsShowsUpgradeButton() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        XCTAssertTrue(app.buttons["upgradeProButton"].waitForExistence(timeout: 12), "Upgrade button did not appear in Settings")
    }

    func testDeleteEntryFromHistory() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["petNameLabel_Buddy"].waitForExistence(timeout: 12))

        // Seed pet has 3 entries; open the ellipsis menu on the first visible one and delete.
        let menus = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'entryMenu_Buddy_'"))
        XCTAssertTrue(menus.firstMatch.waitForExistence(timeout: 12))
        menus.firstMatch.tap()

        let deleteItem = app.buttons["Delete"]
        XCTAssertTrue(deleteItem.waitForExistence(timeout: 8))
        deleteItem.tap()

        // App should not crash and pet card should still be present.
        XCTAssertTrue(app.buttons["petNameLabel_Buddy"].waitForExistence(timeout: 12))
    }
}
