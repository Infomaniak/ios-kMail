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

import Foundation
import InfomaniakCoreUI
import InfomaniakDI
import SwiftUI

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
    static let appReview = MatomoUtils.EventCategory(displayName: "appReview")
    static let createFolder = MatomoUtils.EventCategory(displayName: "createFolder")
    static let externals = MatomoUtils.EventCategory(displayName: "externals")
    static let invalidPasswordMailbox = MatomoUtils.EventCategory(displayName: "invalidPasswordMailbox")
    static let menuDrawer = MatomoUtils.EventCategory(displayName: "menuDrawer")
    static let message = MatomoUtils.EventCategory(displayName: "message")
    static let multiSelection = MatomoUtils.EventCategory(displayName: "multiSelection")
    static let newMessage = MatomoUtils.EventCategory(displayName: "newMessage")
    static let noValidMailboxes = MatomoUtils.EventCategory(displayName: "noValidMailboxes")
    static let onboarding = MatomoUtils.EventCategory(displayName: "onboarding")
    static let replyBottomSheet = MatomoUtils.EventCategory(displayName: "replyBottomSheet")
    static let restoreEmailsBottomSheet = MatomoUtils.EventCategory(displayName: "restoreEmailsBottomSheet")
    static let search = MatomoUtils.EventCategory(displayName: "search")
    static let snackbar = MatomoUtils.EventCategory(displayName: "snackbar")
    static let syncAutoConfig = MatomoUtils.EventCategory(displayName: "syncAutoConfig")
    static let threadList = MatomoUtils.EventCategory(displayName: "threadList")
    static let userInfo = MatomoUtils.EventCategory(displayName: "userInfo")

    // Actions

    static let attachmentActions = MatomoUtils.EventCategory(displayName: "attachmentActions")
    static let bottomSheetMessageActions = MatomoUtils.EventCategory(displayName: "bottomSheetMessageActions")
    static let bottomSheetThreadActions = MatomoUtils.EventCategory(displayName: "bottomSheetThreadActions")
    static let contactActions = MatomoUtils.EventCategory(displayName: "contactActions")
    static let editorActions = MatomoUtils.EventCategory(displayName: "editorActions")
    static let messageActions = MatomoUtils.EventCategory(displayName: "messageActions")
    static let threadActions = MatomoUtils.EventCategory(displayName: "threadActions")
    static let swipeActions = MatomoUtils.EventCategory(displayName: "swipeActions")
    static let notificationAction = MatomoUtils.EventCategory(displayName: "notificationAction")

    // Settings

    static let settingsGeneral = MatomoUtils.EventCategory(displayName: "settingsGeneral")
    static let settingsAccentColor = MatomoUtils.EventCategory(displayName: "settingsAccentColor")
    static let settingsCancelPeriod = MatomoUtils.EventCategory(displayName: "settingsCancelPeriod")
    static let settingsDensity = MatomoUtils.EventCategory(displayName: "settingsDensity")
    static let settingsForwardMode = MatomoUtils.EventCategory(displayName: "settingsForwardMode")
    static let settingsNotifications = MatomoUtils.EventCategory(displayName: "settingsNotifications")
    static let settingsTheme = MatomoUtils.EventCategory(displayName: "settingsTheme")
    static let settingsSend = MatomoUtils.EventCategory(displayName: "settingsSend")
    static let settingsSwipeActions = MatomoUtils.EventCategory(displayName: "settingsSwipeActions")
    static let settingsThreadMode = MatomoUtils.EventCategory(displayName: "settingsThreadMode")
    static let settingsDisplayExternalContent = MatomoUtils.EventCategory(displayName: "settingsDisplayExternalContent")
}

// MARK: - Helpers

public extension MatomoUtils {
    func trackSendMessage(draft: Draft, sentWithExternals: Bool) {
        track(eventWithCategory: .newMessage, name: "sendMail")

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
}

// MARK: - Track views

struct MatomoView: ViewModifier {
    let view: [String]

    func body(content: Content) -> some View {
        content
            .onAppear {
                @InjectService var matomo: MatomoUtils
                matomo.track(view: view)
            }
    }
}

public extension View {
    func matomoView(view: [String]) -> some View {
        modifier(MatomoView(view: view))
    }
}
