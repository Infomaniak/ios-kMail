/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import MailCore
import MailResources
import XCTest

class MailUITests: XCTestCase {
    let defaultTimeOut = TimeInterval(15)
    static let testSubject = "UI Test"

    let app = XCUIApplication()

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
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
        _ = app.webViews.firstMatch.waitForExistence(timeout: defaultTimeOut)
    }

    func testNewMessage() throws {
        launchAppFromScratch()
        login()

        app.buttons[MailResourcesStrings.Localizable.buttonNewMessage].firstMatch.tap()
        _ = app.webViews.firstMatch.waitForExistence(timeout: defaultTimeOut)
    }

    func testSendNewMessage() throws {
        launchAppFromScratch()
        login()
        writeTestMessage()

        app.navigationBars[MailResourcesStrings.Localizable.buttonNewMessage].buttons[MailResourcesStrings.Localizable.send].tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: defaultTimeOut)
    }

    func testSaveMessage() throws {
        launchAppFromScratch()
        login()
        writeTestMessage()

        app.navigationBars[MailResourcesStrings.Localizable.buttonNewMessage]
            .buttons[MailResourcesStrings.Localizable.buttonClose].tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: defaultTimeOut)

        let deleteDraftButton = app.buttons[MailResourcesStrings.Localizable.actionDelete]
        _ = deleteDraftButton.waitForExistence(timeout: defaultTimeOut)
        deleteDraftButton.tap()
    }

    func testSwitchFolder() {
        launchAppFromScratch()
        login()

        app.navigationBars.firstMatch.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonMenu].tap()
        app.scrollViews.otherElements.staticTexts[MailResourcesStrings.Localizable.archiveFolder].tap()
    }

    func testCreateFolder() {
        launchAppFromScratch()
        login()

        app.navigationBars.firstMatch.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonMenu].tap()
        let newFolderButton = app.scrollViews.otherElements.buttons[MailResourcesStrings.Localizable.newFolderDialogTitle]
        _ = newFolderButton.waitForExistence(timeout: defaultTimeOut)
        newFolderButton.tap()

        let folderNameTextField = app.textFields[MailResourcesStrings.Localizable.createFolderName]
        _ = folderNameTextField.waitForExistence(timeout: defaultTimeOut)
        folderNameTextField.tap()
        folderNameTextField.typeText("Test-\(Date().timeIntervalSince1970)")
        app.staticTexts[MailResourcesStrings.Localizable.buttonCreate].tap()
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
        _ = moveFolderViewTitle.waitForExistence(timeout: defaultTimeOut)

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
        app.buttons[Action.delete.accessibilityIdentifier].tap()

        undo()

        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].tap()
        app.buttons[Action.archive.accessibilityIdentifier].tap()

        undo()

        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].tap()
        if app.buttons[Action.markAsRead.accessibilityIdentifier].exists {
            app.buttons[Action.markAsRead.accessibilityIdentifier].tap()
        } else {
            app.buttons[Action.markAsUnread.accessibilityIdentifier].tap()
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
        _ = cancelButton.waitForExistence(timeout: defaultTimeOut)

        if !cancelButton.exists && ignoreUndoFailure {
            return
        }

        cancelButton.tap()
    }

    func swipeFirstCell() {
        let testMailCell = app.collectionViews.cells.element(boundBy: 1)
        _ = testMailCell.waitForExistence(timeout: defaultTimeOut)
        testMailCell.firstMatch.swipeLeft()
    }

    func writeTestMessage() {
        app.buttons[MailResourcesStrings.Localizable.buttonNewMessage].firstMatch.tap()
        let composeBodyView = app.webViews.firstMatch
        _ = composeBodyView.waitForExistence(timeout: defaultTimeOut)

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
        _ = loginButton.waitForExistence(timeout: defaultTimeOut)
        loginButton.tap()
        let loginWebview = app.webViews.firstMatch

        let emailField = loginWebview.textFields.firstMatch
        _ = emailField.waitForExistence(timeout: defaultTimeOut)
        emailField.tap()
        emailField.typeText(Env.testAccountEmail)

        let passwordField = loginWebview.secureTextFields.firstMatch
        passwordField.tap()
        passwordField.typeText(Env.testAccountPassword)
        passwordField.typeText("\n")

        let nextButton = app.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonNext]
        let permissionApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        _ = nextButton.waitForExistence(timeout: defaultTimeOut)
        if nextButton.exists {
            nextButton.tap()

            permissionApp.alerts.firstMatch.buttons.firstMatch.tap()
        }

        _ = nextButton.waitForExistence(timeout: defaultTimeOut)
        if nextButton.exists {
            app.buttons.firstMatch.tap()

            permissionApp.alerts.firstMatch.buttons.firstMatch.tap()
        }

        let refreshText = app.staticTexts[Date().formatted(.relative(presentation: .named))]
        _ = refreshText.waitForExistence(timeout: defaultTimeOut)
    }
}
