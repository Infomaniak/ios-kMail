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
    let defaultTimeOut = TimeInterval(30)
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

        app.navigationBars[MailResourcesStrings.Localizable.buttonNewMessage].buttons[MailResourcesStrings.Localizable.send]
            .firstMatch.tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: defaultTimeOut)
    }

    func testSaveMessage() throws {
        launchAppFromScratch()
        login()
        writeTestMessage()

        app.navigationBars[MailResourcesStrings.Localizable.buttonNewMessage]
            .buttons[MailResourcesStrings.Localizable.buttonClose].firstMatch.tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: defaultTimeOut)

        let deleteDraftButton = app.buttons[MailResourcesStrings.Localizable.actionDelete].firstMatch
        _ = deleteDraftButton.waitForExistence(timeout: defaultTimeOut)
        deleteDraftButton.tap()
    }

    func testSwitchFolder() {
        launchAppFromScratch()
        login()

        app.navigationBars.firstMatch.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonMenu].firstMatch.tap()
        app.scrollViews.otherElements.staticTexts[MailResourcesStrings.Localizable.archiveFolder].firstMatch.tap()
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

        app.collectionViews.buttons[Action.delete.accessibilityIdentifier].firstMatch.tap()

        undo()
    }

    func testUndoDeleteAction() {
        launchAppFromScratch()
        login()
        swipeFirstCell()

        app.collectionViews.buttons[Action.delete.accessibilityIdentifier].firstMatch.tap()

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

        // Because the burger menu is in a ZStack "trash" folder appears twice, that's why we use element bound by
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

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].firstMatch.tap()
        app.buttons[Action.delete.accessibilityIdentifier].tap()

        undo()

        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].firstMatch.tap()
        app.buttons[Action.archive.accessibilityIdentifier].firstMatch.tap()

        undo()

        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].firstMatch.tap()
        if app.buttons[Action.markAsRead.accessibilityIdentifier].firstMatch.exists {
            app.buttons[Action.markAsRead.accessibilityIdentifier].firstMatch.tap()
        } else {
            app.buttons[Action.markAsUnread.accessibilityIdentifier].firstMatch.tap()
        }

        swipeFirstCell()

        app.collectionViews.buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].firstMatch.tap()
        if app.buttons[MailResourcesStrings.Localizable.actionMarkAsUnread].firstMatch.exists {
            app.buttons[MailResourcesStrings.Localizable.actionMarkAsUnread].firstMatch.tap()
        } else {
            app.buttons[MailResourcesStrings.Localizable.actionMarkAsRead].firstMatch.tap()
        }
    }

    func undo(ignoreUndoFailure: Bool = true) {
        let cancelButton = app.buttons[MailResourcesStrings.Localizable.buttonCancel].firstMatch
        _ = cancelButton.waitForExistence(timeout: defaultTimeOut)

        if !cancelButton.exists && ignoreUndoFailure {
            return
        }

        cancelButton.tap()
    }

    func swipeFirstCell() {
        // First cell could be the loading indicator so we get the second one
        let testMailCell = app.collectionViews.containing(.button, identifier: "ThreadListCell").firstMatch
        _ = testMailCell.waitForExistence(timeout: defaultTimeOut)
        testMailCell.swipeLeft()
    }

    func writeTestMessage() {
        app.buttons[MailResourcesStrings.Localizable.buttonNewMessage].firstMatch.tap()
        let composeBodyView = app.webViews.firstMatch
        _ = composeBodyView.waitForExistence(timeout: defaultTimeOut)

        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText(Env.testAccountEmail)
        app.textFields.firstMatch.typeText("\n")

        let subjectTextField = app.textFields[MailResourcesStrings.Localizable.subjectTitle].firstMatch
        subjectTextField.tap()
        subjectTextField.typeText(MailUITests.testSubject)

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
        let loginWebView = app.webViews.firstMatch

        let emailField = loginWebView.textFields.firstMatch
        _ = emailField.waitForExistence(timeout: defaultTimeOut)
        emailField.tap()
        emailField.typeText(Env.testAccountEmail)

        let passwordField = loginWebView.secureTextFields.firstMatch
        passwordField.tap()
        passwordField.typeText(Env.testAccountPassword)
        passwordField.typeText("\n")

        let nowText = MailResourcesStrings.Localizable
            .threadListHeaderLastUpdate(Date().formatted(.relative(presentation: .named)))
        let refreshText = app.staticTexts[nowText].firstMatch
        let alreadyAskedPermissions = refreshText.waitForExistence(timeout: defaultTimeOut)

        if !alreadyAskedPermissions {
            let nextButton = app.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonNext].firstMatch
            _ = nextButton.waitForExistence(timeout: defaultTimeOut)

            let permissionApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            if nextButton.exists {
                nextButton.tap()

                let authorizeButton = permissionApp.alerts.firstMatch.buttons.firstMatch
                if authorizeButton.exists {
                    authorizeButton.tap()
                }
            }

            _ = nextButton.waitForExistence(timeout: defaultTimeOut)
            if nextButton.exists {
                app.buttons.firstMatch.tap()

                let authorizeButton = permissionApp.alerts.firstMatch.buttons.firstMatch
                if authorizeButton.exists {
                    authorizeButton.tap()
                }
            }

            let refreshText = app.staticTexts[nowText].firstMatch
            _ = refreshText.waitForExistence(timeout: defaultTimeOut)
        }
    }
}
