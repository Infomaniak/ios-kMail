/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import Foundation
import InfomaniakCoreCommonUI

// MARK: - Views and Categories

public extension MatomoUtils.View {
    static let accountView = MatomoUtils.View(displayName: "AccountView")
    static let bottomSheet = MatomoUtils.View(displayName: "BottomSheet")
    static let onboarding = MatomoUtils.View(displayName: "Onboarding")
    static let threadListView = MatomoUtils.View(displayName: "ThreadListView")
    static let threadView = MatomoUtils.View(displayName: "ThreadView")
    static let settingsView = MatomoUtils.View(displayName: "SettingsView")
}

public extension MatomoUtils.EventCategory {
    // General

    static let aiWriter = MatomoUtils.EventCategory(displayName: "aiWriter")
    static let calendarEvent = MatomoUtils.EventCategory(displayName: "calendarEvent")
    static let createFolder = MatomoUtils.EventCategory(displayName: "createFolder")
    static let manageFolder = MatomoUtils.EventCategory(displayName: "manageFolder")
    static let emojiReactions = MatomoUtils.EventCategory(displayName: "emojiReactions")
    static let easterEgg = MatomoUtils.EventCategory(displayName: "easterEgg")
    static let externals = MatomoUtils.EventCategory(displayName: "externals")
    static let homeScreenShortcuts = MatomoUtils.EventCategory(displayName: "homeScreenShortcuts")
    static let kSuiteProUpgradeBottomSheet = MatomoUtils.EventCategory(displayName: "kSuiteProUpgradeBottomSheet")
    static let mailPremiumUpgradeBottomSheet = MatomoUtils.EventCategory(displayName: "mailPremiumUpgradeBottomSheet")
    static let menuDrawer = MatomoUtils.EventCategory(displayName: "menuDrawer")
    static let message = MatomoUtils.EventCategory(displayName: "message")
    static let multiSelection = MatomoUtils.EventCategory(displayName: "multiSelection")
    static let myKSuite = MatomoUtils.EventCategory(displayName: "myKSuite")
    static let myKSuiteUpgradeBottomSheet = MatomoUtils.EventCategory(displayName: "myKSuiteUpgradeBottomSheet")
    static let newMessage = MatomoUtils.EventCategory(displayName: "newMessage")
    static let noValidMailboxes = MatomoUtils.EventCategory(displayName: "noValidMailboxes")
    static let onboarding = MatomoUtils.EventCategory(displayName: "onboarding")
    static let replyBottomSheet = MatomoUtils.EventCategory(displayName: "replyBottomSheet")
    static let restoreEmailsBottomSheet = MatomoUtils.EventCategory(displayName: "restoreEmailsBottomSheet")
    static let scheduleSend = MatomoUtils.EventCategory(displayName: "scheduleSend")
    static let search = MatomoUtils.EventCategory(displayName: "search")
    static let searchMultiSelection = MatomoUtils.EventCategory(displayName: "searchMultiSelection")
    static let setAsDefaultApp = MatomoUtils.EventCategory(displayName: "setAsDefaultApp")
    static let snackbar = MatomoUtils.EventCategory(displayName: "snackbar")
    static let snooze = MatomoUtils.EventCategory(displayName: "snooze")
    static let syncAutoConfig = MatomoUtils.EventCategory(displayName: "syncAutoConfig")
    static let threadList = MatomoUtils.EventCategory(displayName: "threadList")
    static let updateVersion = MatomoUtils.EventCategory(displayName: "updateVersion")
    static let userInfo = MatomoUtils.EventCategory(displayName: "userInfo")
    static let messageBanner = MatomoUtils.EventCategory(displayName: "messageBanner")

    // Actions

    static let attachmentActions = MatomoUtils.EventCategory(displayName: "attachmentActions")
    static let blockUserAction = MatomoUtils.EventCategory(displayName: "blockUserAction")
    static let bottomSheetMessageActions = MatomoUtils.EventCategory(displayName: "bottomSheetMessageActions")
    static let bottomSheetThreadActions = MatomoUtils.EventCategory(displayName: "bottomSheetThreadActions")
    static let contactActions = MatomoUtils.EventCategory(displayName: "contactActions")
    static let editorActions = MatomoUtils.EventCategory(displayName: "editorActions")
    static let keyboardShortcutActions = MatomoUtils.EventCategory(displayName: "keyboardShortcutActions")
    static let menuAction = MatomoUtils.EventCategory(displayName: "menuAction")
    static let messageActions = MatomoUtils.EventCategory(displayName: "messageActions")
    static let notificationActions = MatomoUtils.EventCategory(displayName: "notificationActions")
    static let swipeActions = MatomoUtils.EventCategory(displayName: "swipeActions")
    static let threadActions = MatomoUtils.EventCategory(displayName: "threadActions")

    // Settings

    static let settingsGeneral = MatomoUtils.EventCategory(displayName: "settingsGeneral")
    static let settingsAccentColor = MatomoUtils.EventCategory(displayName: "settingsAccentColor")
    static let settingsAutoAdvance = MatomoUtils.EventCategory(displayName: "settingsAutoAdvance")
    static let settingsCancelPeriod = MatomoUtils.EventCategory(displayName: "settingsCancelPeriod")
    static let settingsDataPrivacy = MatomoUtils.EventCategory(displayName: "settingsDataPrivacy")
    static let settingsDensity = MatomoUtils.EventCategory(displayName: "settingsDensity")
    static let settingsDisplayExternalContent = MatomoUtils.EventCategory(displayName: "settingsDisplayExternalContent")
    static let settingsForwardMode = MatomoUtils.EventCategory(displayName: "settingsForwardMode")
    static let settingsNotifications = MatomoUtils.EventCategory(displayName: "settingsNotifications")
    static let settingsSend = MatomoUtils.EventCategory(displayName: "settingsSend")
    static let settingsSwipeActions = MatomoUtils.EventCategory(displayName: "settingsSwipeActions")
    static let settingsTheme = MatomoUtils.EventCategory(displayName: "settingsTheme")
    static let settingsThreadMode = MatomoUtils.EventCategory(displayName: "settingsThreadMode")
}

// MARK: - Helpers

public extension MatomoUtils {
    func trackSendMessage(draft: Draft, sentWithExternals: Bool) {
        track(eventWithCategory: .newMessage, name: draft.scheduleDate == nil ? "sendMail" : "scheduleDraft")

        track(eventWithCategory: .newMessage, action: .data, name: "numberOfTo", value: Float(draft.to.count))
        track(eventWithCategory: .newMessage, action: .data, name: "numberOfCc", value: Float(draft.cc.count))
        track(eventWithCategory: .newMessage, action: .data, name: "numberOfBcc", value: Float(draft.bcc.count))

        track(eventWithCategory: .externals, action: .data, name: "emailSentWithExternals", value: sentWithExternals)
    }

    func trackThreadInfo(of thread: Thread) {
        let messagesCount = Float(thread.messages.count)

        track(eventWithCategory: .userInfo, action: .data, name: "nbMessagesInThread", value: messagesCount)

        if messagesCount == 1 {
            track(eventWithCategory: .userInfo, action: .data, name: "oneMessagesInThread")
        } else if messagesCount > 1 {
            track(eventWithCategory: .userInfo, action: .data, name: "multipleMessagesInThread", value: messagesCount)
        }
    }

    func trackThreadBottomSheetAction(action: Action, origin: ActionOrigin, numberOfItems: Int, isMultipleSelection: Bool) {
        let category: MatomoUtils.EventCategory = origin.type == .floatingPanel(source: .message)
            ? .bottomSheetMessageActions
            : .bottomSheetThreadActions

        if isMultipleSelection {
            trackBulkEvent(eventWithCategory: category, name: action.matomoName, numberOfItems: numberOfItems)
        } else {
            track(eventWithCategory: category, name: action.matomoName)
        }
    }
}
