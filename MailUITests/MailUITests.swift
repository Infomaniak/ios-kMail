/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import MailResources
import XCTest

class MailUITests: XCTestCase {
    static let testSubject = "UI Test"

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func launchAppFromScratch(resetData: Bool = true) {
        let app = XCUIApplication()
        if resetData {
            app.launchArguments += ["resetData"]
        }
        app.launch()
    }

    func testLogin() throws {
        launchAppFromScratch()
        login()
    }

    func testDisplayThread() throws {
        launchAppFromScratch()
        login()
        let app = XCUIApplication()

        app.collectionViews.staticTexts.element(boundBy: 1).firstMatch.tap()
        _ = app.webViews.firstMatch.waitForExistence(timeout: 3)
    }

    func testNewMessage() throws {
        launchAppFromScratch()
        login()
        let app = XCUIApplication()

        app.buttons.containing(NSPredicate(format: "label = %@", MailResourcesStrings.Localizable.buttonNewMessage))
            .firstMatch.tap()
        _ = app.webViews.firstMatch.waitForExistence(timeout: 3)
    }

    func testSendNewMessage() throws {
        launchAppFromScratch()
        login()
        writeTestMessage()

        let app = XCUIApplication()
        app.navigationBars[MailResourcesStrings.Localizable.buttonNewMessage].buttons[MailResourcesStrings.Localizable.send].tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: 2)
    }

    func testSaveMessage() throws {
        launchAppFromScratch()
        login()
        writeTestMessage()

        let app = XCUIApplication()
        app.navigationBars[MailResourcesStrings.Localizable.buttonNewMessage]
            .buttons[MailResourcesStrings.Localizable.buttonClose].tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: 2)
    }

    func testSwitchFolder() {
        launchAppFromScratch()
        login()

        let app = XCUIApplication()
        app.navigationBars.firstMatch.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonMenu].tap()
        app.scrollViews.otherElements.staticTexts[MailResourcesStrings.Localizable.archiveFolder].tap()
    }

    func testDeleteSwipeAction() {
        launchAppFromScratch(resetData: false)
        login()
        let app = XCUIApplication()

        let testMailCell = app.collectionViews.cells.element(boundBy: 1)
        let _ = testMailCell.waitForExistence(timeout: 10)
        testMailCell.firstMatch.swipeLeft()
        app.collectionViews.buttons[MailResourcesStrings.Localizable.actionDelete].tap()
    }

    func testMoreSwipeActionThenDelete() {
        launchAppFromScratch()
        login()
        let app = XCUIApplication()

        let testMailCell = app.collectionViews.cells.element(boundBy: 1)
        let _ = testMailCell.waitForExistence(timeout: 10)
        testMailCell.firstMatch.swipeLeft()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].tap()
        app.buttons[MailResourcesStrings.Localizable.actionDelete].tap()
    }

    func writeTestMessage() {
        let app = XCUIApplication()

        app.buttons.containing(NSPredicate(format: "label = %@", MailResourcesStrings.Localizable.buttonNewMessage))
            .firstMatch.tap()
        let composeBodyView = app.webViews.firstMatch
        _ = composeBodyView.waitForExistence(timeout: 3)

        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText(Env.testAccountEmail)
        app.textFields.firstMatch.typeText("\n")

        let scrollViewsQuery = app.scrollViews
        let textView = scrollViewsQuery.otherElements.containing(
            .staticText,
            identifier: MailResourcesStrings.Localizable.fromTitle
        ).children(matching: .textView).element(boundBy: 1)
        textView.tap()
        textView.typeText(MailUITests.testSubject)

        composeBodyView.tap()
        composeBodyView.typeText(MailResourcesStrings.Localizable.aiPromptExample1)
    }

    func login() {
        let app = XCUIApplication()

        app.buttons.containing(NSPredicate(format: "label = %@", MailResourcesStrings.Localizable.contentDescriptionButtonNext))
            .firstMatch.tap()
        app.buttons.containing(NSPredicate(format: "label = %@", MailResourcesStrings.Localizable.contentDescriptionButtonNext))
            .firstMatch.tap()
        app.buttons.containing(NSPredicate(format: "label = %@", MailResourcesStrings.Localizable.contentDescriptionButtonNext))
            .firstMatch.tap()
        let loginButton = app.buttons.containing(NSPredicate(format: "label = %@", MailResourcesStrings.Localizable.buttonLogin))
            .firstMatch
        let _ = loginButton.waitForExistence(timeout: 2)
        loginButton.tap()
        let loginWebview = app.webViews.firstMatch

        let emailField = loginWebview.textFields.firstMatch
        let _ = emailField.waitForExistence(timeout: 5)
        emailField.tap()
        emailField.typeText(Env.testAccountEmail)

        let passwordField = loginWebview.secureTextFields.firstMatch
        passwordField.tap()
        passwordField.typeText(Env.testAccountPassword)
        passwordField.typeText("\n")

        let nextButton = app.buttons.containing(NSPredicate(
            format: "label = %@",
            MailResourcesStrings.Localizable.contentDescriptionButtonNext
        )).firstMatch
        let permissionApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        let _ = nextButton.waitForExistence(timeout: 1)
        if nextButton.exists {
            nextButton.tap()

            permissionApp.alerts.firstMatch.buttons.firstMatch.tap()
        }

        if nextButton.exists {
            app.buttons.firstMatch.tap()

            permissionApp.alerts.firstMatch.buttons.firstMatch.tap()
        }

        let refreshText = app.staticTexts[Date().formatted(.relative(presentation: .named))]
        _ = refreshText.waitForExistence(timeout: 5)
    }
}
