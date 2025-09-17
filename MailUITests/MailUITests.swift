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

import InfomaniakCoreUIResources
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
        app.launchArguments += ["UI-Testing"]
        app.launch()
    }

    func wait(delay: TimeInterval = 5) {
        let delayExpectation = XCTestExpectation()
        delayExpectation.isInverted = true
        wait(for: [delayExpectation], timeout: delay)
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

    func testSendNewMessage() throws {
        launchAppFromScratch()
        login()
        writeTestMessage()

        app.navigationBars.buttons[MailResourcesStrings.Localizable.send]
            .firstMatch.tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: defaultTimeOut)

        refreshThreadList()

        let newEmail = app.collectionViews.staticTexts[MailUITests.testSubject].firstMatch
        XCTAssertTrue(newEmail.waitForExistence(timeout: defaultTimeOut))

        swipeFirstCell()

        let deleteButton = app.collectionViews.buttons[Action.delete.accessibilityIdentifier].firstMatch
        _ = deleteButton.waitForExistence(timeout: defaultTimeOut)
        deleteButton.tap()
    }

    func testSaveMessage() throws {
        launchAppFromScratch()
        login()
        let subject = "\(MailUITests.testSubject) - \(Date().timeIntervalSince1970)"
        writeTestMessage(subject: subject)

        app.navigationBars.buttons[MailResourcesStrings.Localizable.buttonCancel].firstMatch.tap()

        tapMenuButton()

        app.scrollViews.otherElements.staticTexts[MailResourcesStrings.Localizable.draftFolder].firstMatch.tap()

        let newEmail = app.collectionViews.staticTexts[subject].firstMatch
        XCTAssertTrue(newEmail.waitForExistence(timeout: defaultTimeOut))
        newEmail.tap()

        let subjectText = app.staticTexts[subject]
        XCTAssertTrue(subjectText.waitForExistence(timeout: defaultTimeOut))

        let bodyText = app.staticTexts[MailResourcesStrings.Localizable.aiPromptExample1]
        XCTAssertTrue(bodyText.waitForExistence(timeout: defaultTimeOut))

        app.buttons[MailResourcesStrings.Localizable.buttonCancel].firstMatch.tap()

        wait(delay: 15)

        swipeCustomCell(with: subject)

        let deleteDraftButton = app.buttons[MailResourcesStrings.Localizable.actionDelete].firstMatch
        _ = deleteDraftButton.waitForExistence(timeout: defaultTimeOut)
        deleteDraftButton.tap()
    }

    func tapMenuButton() {
        let menuButton = app.navigationBars.firstMatch.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonMenu]
            .firstMatch
        _ = menuButton.waitForExistence(timeout: defaultTimeOut)
        menuButton.tap()
    }

    func testSwitchFolder() {
        launchAppFromScratch()
        login()

        tapMenuButton()

        app.scrollViews.otherElements.staticTexts[MailResourcesStrings.Localizable.archiveFolder].firstMatch.tap()
    }

    func testCreateFolder() {
        launchAppFromScratch()
        login()

        tapMenuButton()

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

        let deleteButton = app.collectionViews.buttons[Action.delete.accessibilityIdentifier].firstMatch
        _ = deleteButton.waitForExistence(timeout: defaultTimeOut)
        deleteButton.tap()

        undo()
    }

    func testUndoDeleteAction() {
        launchAppFromScratch()
        login()
        swipeFirstCell()

        let deleteButton = app.collectionViews.buttons[Action.delete.accessibilityIdentifier].firstMatch
        _ = deleteButton.waitForExistence(timeout: defaultTimeOut)
        deleteButton.tap()

        undo(ignoreUndoFailure: false)
    }

    func testMoveAction() {
        launchAppFromScratch()
        login()
        swipeFirstCell()

        tapSwipeActionQuickActionsMenu()
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

    func tapSwipeActionQuickActionsMenu() {
        let quickActionsMenuButton = app.collectionViews
            .buttons[MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu].firstMatch
        _ = quickActionsMenuButton.waitForExistence(timeout: defaultTimeOut)
        quickActionsMenuButton.tap()
    }

    func testMoreSwipeAction() {
        launchAppFromScratch()
        login()
        swipeFirstCell()

        tapSwipeActionQuickActionsMenu()
        app.buttons[Action.delete.accessibilityIdentifier].tap()

        undo()

        swipeFirstCell()

        tapSwipeActionQuickActionsMenu()
        app.buttons[Action.archive.accessibilityIdentifier].firstMatch.tap()

        undo()

        swipeFirstCell()

        tapSwipeActionQuickActionsMenu()
        if app.buttons[Action.markAsRead.accessibilityIdentifier].firstMatch.exists {
            app.buttons[Action.markAsRead.accessibilityIdentifier].firstMatch.tap()
        } else {
            app.buttons[Action.markAsUnread.accessibilityIdentifier].firstMatch.tap()
        }

        swipeFirstCell()

        tapSwipeActionQuickActionsMenu()
        if app.buttons[MailResourcesStrings.Localizable.actionMarkAsUnread].firstMatch.exists {
            app.buttons[MailResourcesStrings.Localizable.actionMarkAsUnread].firstMatch.tap()
        } else {
            app.buttons[MailResourcesStrings.Localizable.actionMarkAsRead].firstMatch.tap()
        }
    }

    func testSendMessageToDraftWithAttachment() throws {
        launchAppFromScratch()
        login()
        writeTestMessage()

        let addAttachmentButton = app.buttons[MailResourcesStrings.Localizable.attachmentActionTitle].firstMatch
        _ = addAttachmentButton.waitForExistence(timeout: defaultTimeOut)
        addAttachmentButton.tap()

        app.buttons[CoreUILocalizable.buttonUploadFromGallery].firstMatch.tap()

        let firstPhoto = app.otherElements["photos_layout"].images.firstMatch
        _ = firstPhoto.waitForExistence(timeout: defaultTimeOut)
        firstPhoto.tap()

        let addButton = app.buttons["Add"]
        _ = addButton.waitForExistence(timeout: defaultTimeOut)
        addButton.tap()

        wait(delay: 15)

        app.navigationBars.buttons[MailResourcesStrings.Localizable.buttonCancel].firstMatch.tap()

        let deleteDraftButton = app.buttons[MailResourcesStrings.Localizable.actionDelete].firstMatch
        _ = deleteDraftButton.waitForExistence(timeout: defaultTimeOut)
        deleteDraftButton.tap()
    }

    func testSearchBar() {
        launchAppFromScratch()
        login()
        writeTestMessage()

        app.navigationBars.buttons[MailResourcesStrings.Localizable.send]
            .firstMatch.tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: defaultTimeOut)

        refreshThreadList()

        app.buttons[MailResourcesStrings.Localizable.searchAction].tap()
        app.staticTexts[MailResourcesStrings.Localizable.searchFilterUnread].tap()
        app.collectionViews.cells.buttons.firstMatch.tap()

        let matchingSubject = app.staticTexts[MailUITests.testSubject]
        XCTAssertTrue(matchingSubject.waitForExistence(timeout: defaultTimeOut))
        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: defaultTimeOut))
        app.buttons[MailResourcesStrings.Localizable.actionDelete].tap()
    }

    func refreshThreadList() {
        let threadList = app.collectionViews.firstMatch
        _ = threadList.waitForExistence(timeout: defaultTimeOut)
        threadList.swipeDown()
        wait(delay: 15)
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
        let testMailCell = app.collectionViews.cells.element(boundBy: 1)
        _ = testMailCell.waitForExistence(timeout: defaultTimeOut)
        testMailCell.swipeLeft()
        wait(delay: 15)
    }

    func swipeCustomCell(with text: String) {
        let matchingCell = app.collectionViews.cells.containing(.staticText, identifier: text).firstMatch
        XCTAssertTrue(matchingCell.waitForExistence(timeout: defaultTimeOut))
        matchingCell.swipeLeft()
    }

    func writeTestMessage(subject: String? = nil) {
        let newMessageButton = app.buttons[MailResourcesStrings.Localizable.buttonNewMessage].firstMatch
        _ = newMessageButton.waitForExistence(timeout: defaultTimeOut)
        newMessageButton.tap()

        let composeBodyView = app.webViews.firstMatch
        _ = composeBodyView.waitForExistence(timeout: defaultTimeOut)

        let toTextField = app.textFields.firstMatch
        _ = toTextField.waitForExistence(timeout: defaultTimeOut)
        toTextField.tap()
        toTextField.typeText(Env.testAccountEmail)
        toTextField.typeText("\n")

        let subjectTextField = app.textFields[MailResourcesStrings.Localizable.subjectTitle].firstMatch
        subjectTextField.tap()
        subjectTextField.typeText(subject ?? MailUITests.testSubject)

        composeBodyView.tap()
        composeBodyView.typeText(MailResourcesStrings.Localizable.aiPromptExample1)

        wait(delay: 15)
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

        wait(delay: 5)

        let nowText = MailResourcesStrings.Localizable
            .threadListHeaderLastUpdate(Date().formatted(.relative(presentation: .named)))
        let refreshText = app.staticTexts[nowText].firstMatch
        let alreadyAskedPermissions = refreshText.waitForExistence(timeout: defaultTimeOut)

        if !alreadyAskedPermissions {
            let nextButton = app.buttons[MailResourcesStrings.Localizable.contentDescriptionButtonNext].firstMatch
            _ = nextButton.waitForExistence(timeout: defaultTimeOut)

            if nextButton.exists {
                nextButton.tap()

                let permissionApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                let authorizeButton = permissionApp.alerts.firstMatch.buttons.firstMatch
                if authorizeButton.exists {
                    authorizeButton.tap()
                }

                let contactsPermissionApp = XCUIApplication(bundleIdentifier: "com.apple.ContactsUI.LimitedAccessPromptView")
                if contactsPermissionApp.state == .runningForeground {
                    let shareAll = contactsPermissionApp.buttons.allElementsBoundByIndex[1].firstMatch
                    if shareAll.exists {
                        shareAll.tap()
                    }
                }
            }

            _ = nextButton.waitForExistence(timeout: defaultTimeOut)
            if nextButton.exists {
                app.buttons.firstMatch.tap()

                let permissionApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                let authorizeButton = permissionApp.alerts.firstMatch.buttons.firstMatch
                if authorizeButton.exists {
                    authorizeButton.tap()
                }
            }

            let refreshText = app.staticTexts[nowText].firstMatch
            _ = refreshText.waitForExistence(timeout: defaultTimeOut)
        }

        wait(delay: 15)
    }
}
