/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import InfomaniakCore
import InfomaniakDI
import MailResources
import SwiftUI

public class ActionsProvider: ObservableObject {
    @AppStorage(UserDefaults.shared.key(.swipeFullLeading)) private var swipeFullLeading = DefaultPreferences.swipeFullLeading
    @AppStorage(UserDefaults.shared.key(.swipeLeading)) private var swipeLeading = DefaultPreferences.swipeLeading

    @AppStorage(UserDefaults.shared.key(.swipeFullTrailing)) private var swipeFullTrailing = DefaultPreferences.swipeFullTrailing
    @AppStorage(UserDefaults.shared.key(.swipeTrailing)) private var swipeTrailing = DefaultPreferences.swipeTrailing

    public struct MessageActions {
        public let quickActions: [Action]
        public let listActions: [Action]
        public let euriaActions: [Action]
    }

    enum ToolbarActions {
        static let standardActions: [Action] = [.reply, .forward, .archive, .delete]
        static let archiveActions: [Action] = [.reply, .forward, .openMovePanel, .delete]
        static let scheduleActions: [Action] = [.delete]
    }

    let currentUser: UserProfile
    let currentEmail: String
    let featureAvailableProvider: FeatureAvailableProvider

    public init(currentUser: UserProfile, featureAvailableProvider: FeatureAvailableProvider, currentEmail: String) {
        self.currentUser = currentUser
        self.currentEmail = currentEmail
        self.featureAvailableProvider = featureAvailableProvider
    }

    private func leadingActions(folder: Folder) -> [Action] {
        if !folder.hasLimitedSwipeActions {
            return [swipeFullLeading, swipeLeading]
        }
        return []
    }

    private func trailingActions(folder: Folder) -> [Action] {
        if folder.hasLimitedSwipeActions {
            return [.delete]
        } else {
            return [swipeFullTrailing, swipeTrailing]
        }
    }

    private func swipeActions(origin: ActionOrigin) -> [Action] {
        guard let thread = origin.thread, let folder = origin.frozenFolder else {
            return []
        }
        var actions = [Action]()
        if case .swipe(let direction) = origin.type {
            switch direction {
            case .leading:
                actions = leadingActions(folder: folder)
            case .trailing:
                actions = trailingActions(folder: folder)
            }
        }

        let realActions = actions.map { $0.inverseActionIfNeeded(for: thread) }
        return realActions.filter { action in
            switch action {
            case .noAction:
                return false
            case .snooze:
                return folder.canAccessSnoozeActions(featureAvailableProvider: featureAvailableProvider) == true
            default:
                return true
            }
        }
    }

    func toolbarActions(for mode: ActionOrigin.ToolbarMode, folder: Folder?, messages: [Message]) -> MessageActions {
        guard let folder else { return MessageActions(quickActions: [], listActions: [], euriaActions: []) }

        if mode == .compact {
            return MessageActions(
                quickActions: [],
                listActions: compactToolbarActions(for: messages, folder: folder),
                euriaActions: []
            )
        } else {}
        return MessageActions(quickActions: [], listActions: [], euriaActions: [])
    }

    func compactToolbarActions(for messages: [Message], folder: Folder) -> [Action] {
        let isAllMessagesScheduled = messages.allSatisfy { $0.isScheduledDraft == true }
        if isAllMessagesScheduled {
            return ToolbarActions.scheduleActions
        } else if folder.role == .archive {
            return ToolbarActions.archiveActions
        } else {
            return ToolbarActions.standardActions
        }
    }

    public func actionsFor(origin: ActionOrigin, messages: [Message]) -> MessageActions {
        switch origin.type {
        case .swipe:
            return MessageActions(quickActions: [], listActions: swipeActions(origin: origin), euriaActions: [])
        case .floatingPanel(let source):
            return MessageActions(quickActions: [], listActions: [], euriaActions: [])
        case .toolbar:
            if case .toolbar(let mode) = origin.type {
                return toolbarActions(for: mode, folder: origin.frozenFolder, messages: messages)
            }
        case .multipleSelection:
            return MessageActions(quickActions: [], listActions: [], euriaActions: [])
        case .shortcut:
            return MessageActions(quickActions: [], listActions: [], euriaActions: [])
        case .threadHeader:
            return MessageActions(quickActions: [], listActions: [], euriaActions: [])
        }
        return MessageActions(quickActions: [], listActions: [], euriaActions: [])
    }
}
