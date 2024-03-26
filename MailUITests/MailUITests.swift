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

    let app = XCUIApplication()

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func launchAppFromScratch(resetData: Bool = true) {
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

        app.collectionViews.staticTexts.element(boundBy: 1).firstMatch.tap()
        _ = app.webViews.firstMatch.waitForExistence(timeout: 3)
    }

    func testNewMessage() throws {
        launchAppFromScratch()
        login()

        app.buttons[MailResourcesStrings.Localizable.buttonNewMessage].firstMatch.tap()
        _ = app.webViews.firstMatch.waitForExistence(timeout: 3)
    }

    func testSendNewMessage() throws {
        launchAppFromScratch()
        login()
        writeTestMessage()

        app.navigationBars[MailResourcesStrings.Localizable.buttonNewMessage].buttons[MailResourcesStrings.Localizable.send].tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: 2)
    }

    func testSaveMessage() throws {
        launchAppFromScratch()
        login()
        writeTestMessage()

        app.navigationBars[MailResourcesStrings.Localizable.buttonNewMessage]
            .buttons[MailResourcesStrings.Localizable.buttonClose].tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: 2)

        let deleteDraftButton = app.buttons[MailResourcesStrings.Localizable.actionDelete]
        _ = deleteDraftButton.waitForExistence(timeout: 10)
        deleteDraftButton.tap()
    }

    func testSwitchFolder() {
        launchAppFromScratch()
        login()

        app.navigationBars.firstMatch.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonMenu].tap()
        app.scrollViews.otherElements.staticTexts[MailResourcesStrings.Localizable.archiveFolder].tap()
    }

    func testDeleteSwipeAction() {
        launchAppFromScratch()
        login()
        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.actionDelete].tap()

        undo()
    }

    func testUndoDeleteAction() {
        launchAppFromScratch()
        login()
        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.actionDelete].tap()

        undo(ignoreUndoFailure: false)
    }

    func testMoveAction() {
        launchAppFromScratch()
        login()
        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].tap()
        app.buttons[MailResourcesStrings.Localizable.actionMove].tap()

        let moveFolderViewTitle = app.navigationBars.staticTexts[MailResourcesStrings.Localizable.actionMove]
        _ = moveFolderViewTitle.waitForExistence(timeout: 3)

        // Because the burger menu is in a ZStack "trash" folder appears twice, that's why we use element bound bys
        app.scrollViews.containing(
            .staticText,
            identifier: MailResourcesStrings.Localizable.trashFolder
        ).element(boundBy: 1).tap()

        undo()
    }

    func testMoreSwipeAction() {
        launchAppFromScratch()
        login()
        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].tap()
        app.buttons[MailResourcesStrings.Localizable.actionDelete].tap()

        undo()

        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].tap()
        app.buttons[MailResourcesStrings.Localizable.actionArchive].tap()

        undo()

        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].tap()
        if app.buttons[MailResourcesStrings.Localizable.actionMarkAsRead].exists {
            app.buttons[MailResourcesStrings.Localizable.actionMarkAsRead].tap()
        } else {
            app.buttons[MailResourcesStrings.Localizable.actionMarkAsUnread].tap()
        }

        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].tap()
        if app.buttons[MailResourcesStrings.Localizable.actionMarkAsUnread].exists {
            app.buttons[MailResourcesStrings.Localizable.actionMarkAsUnread].tap()
        } else {
            app.buttons[MailResourcesStrings.Localizable.actionMarkAsRead].tap()
        }
    }

    func undo(ignoreUndoFailure: Bool = true) {
        let cancelButton = app.buttons[MailResourcesStrings.Localizable.buttonCancel]
        _ = cancelButton.waitForExistence(timeout: 10)

        if !cancelButton.exists && ignoreUndoFailure {
            return
        }

        cancelButton.tap()
    }

    func swipeFirstCell() {
        let testMailCell = app.collectionViews.cells.element(boundBy: 1)
        let _ = testMailCell.waitForExistence(timeout: 10)
        testMailCell.firstMatch.swipeLeft()
    }

    func writeTestMessage() {
        app.buttons[MailResourcesStrings.Localizable.buttonNewMessage].firstMatch.tap()
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
        app.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonNext].firstMatch.tap()
        app.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonNext].firstMatch.tap()
        app.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonNext].firstMatch.tap()

        let loginButton = app.buttons[MailResourcesStrings.Localizable.buttonLogin].firstMatch
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

        let nextButton = app.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonNext]
        let permissionApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        let _ = nextButton.waitForExistence(timeout: 3)
        if nextButton.exists {
            nextButton.tap()

            permissionApp.alerts.firstMatch.buttons.firstMatch.tap()
        }

        let _ = nextButton.waitForExistence(timeout: 3)
        if nextButton.exists {
            app.buttons.firstMatch.tap()

            permissionApp.alerts.firstMatch.buttons.firstMatch.tap()
        }

        let refreshText = app.staticTexts[Date().formatted(.relative(presentation: .named))]
        _ = refreshText.waitForExistence(timeout: 5)
    }
}
