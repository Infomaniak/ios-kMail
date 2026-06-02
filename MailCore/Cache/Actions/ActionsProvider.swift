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

    let draftActions = MessageActions(
        quickActions: [],
        listActions: [.shareMailLink, .saveThreadInkDrive],
        euriaActions: []
    )

    private func isSelfThread(_ messages: [Message]) -> Bool {
        return messages.flatMap(\.from).allSatisfy { $0.isMe(currentMailboxEmail: currentEmail) }
    }

    private func euriaActionsForMessage(origin: ActionOrigin) -> [Action] {
        let translate = featureAvailableProvider.isAvailable(.translate) &&
            (origin.type == .floatingPanel(source: .message) || origin.type == .floatingPanel(source: .messageList)
                || origin.type == .toolbar(mode: .compact) || origin.type == .toolbar(mode: .large))
        let summarize = featureAvailableProvider.isAvailable(.summarize) &&
            (origin.type == .floatingPanel(source: .message) || origin.type == .floatingPanel(source: .messageList)
                || origin.type == .toolbar(mode: .compact) || origin.type == .toolbar(mode: .large))

        let tempEuriaActions: [Action?] = [
            summarize ? .summarize : nil,
            translate ? .translateMessage : nil
        ]
        let euriaActions = tempEuriaActions.compactMap { $0 }

        return euriaActions
    }

    private func actionsForMessage(_ message: Message, origin: ActionOrigin) -> MessageActions {
        @LazyInjectService var platformDetector: PlatformDetectable

        let snoozedActions = snoozedActions([message], folder: origin.frozenFolder)
        let euriaActions = euriaActionsForMessage(
            origin: origin
        )

        let isFromMe = message.fromMe(currentMailboxEmail: currentEmail)
        let isInSpamFolder = message.folder?.role == .spam
        var spamAction: Action? {
            guard !isFromMe else { return nil }
            return isInSpamFolder ? .nonSpam : .spam
        }
        let archive = message.folder?.role != .archive
        let unread = !message.seen
        let star = message.flagged
        let print = origin.type == .floatingPanel(source: .message)
        var tempListActions: [Action?] = [
            euriaActions.isEmpty ? nil : .showEuriaActions,
            .openMovePanel,
            unread ? .markAsRead : .markAsUnread,
            spamAction,
            isFromMe ? nil : .phishing,
            isFromMe || isInSpamFolder ? nil : .blockList,
            .shareMailLink,
            archive ? .archive : .moveToInbox,
            star ? .unstar : .star,
            print ? .print : nil,
            platformDetector.isMac ? nil : .saveThreadInkDrive,
            currentUser.isStaff == true ? .reportDisplayProblem : nil
        ]

        if message.isScheduledDraft == true {
            tempListActions.removeAll { $0 == .archive }
        }

        let listActions = snoozedActions + tempListActions.compactMap { $0 }

        return MessageActions(
            quickActions: Action.quickActions,
            listActions: listActions,
            euriaActions: euriaActions
        )
    }

    private func actionsForMessagesInDifferentThreads(_ messages: [Message], originFolder: Folder?) -> MessageActions {
        let unread = messages.allSatisfy(\.seen)
        let archive = originFolder?.role != .archive
        var quickActions: [Action] = [
            .openMovePanel,
            unread ? .markAsUnread : .markAsRead,
            archive ? .archive : .moveToInbox,
            .delete
        ]

        let snoozedActions = snoozedActions(messages, folder: originFolder)

        let isSelfThread = isSelfThread(messages)
        let isInSpamFolder = originFolder?.role == .spam
        var spamAction: Action? {
            guard !isSelfThread else { return nil }
            return isInSpamFolder ? .nonSpam : .spam
        }
        let star = messages.allSatisfy(\.flagged)

        var tempListActions: [Action?] = [
            spamAction,
            isSelfThread ? nil : .phishing,
            isSelfThread || isInSpamFolder ? nil : .blockList,
            star ? .unstar : .star,
            .saveThreadInkDrive
        ]

        if messages.contains(where: { $0.isScheduledDraft == true }) {
            tempListActions.removeAll { $0 == .star || $0 == .unstar }
            quickActions = quickActions.map { action in
                if action == .archive {
                    return star ? .unstar : .star
                }
                return action
            }
        }

        let listActions = snoozedActions + tempListActions.compactMap { $0 }

        return MessageActions(
            quickActions: quickActions,
            listActions: listActions,
            euriaActions: []
        )
    }

    private func actionsForMessagesInSameThreads(_ messages: [Message],
                                                 originFolder: Folder?)
        -> MessageActions {
        let archive = originFolder?.role != .archive
        let unread = messages.allSatisfy(\.seen)
        let showUnstar = messages.contains { $0.flagged }

        let isSelfThread = isSelfThread(messages)
        let isInSpamFolder = originFolder?.role == .spam
        var spamAction: Action? {
            guard !isSelfThread else { return nil }
            return isInSpamFolder ? .nonSpam : .spam
        }

        let snoozedActions = snoozedActions(messages, folder: originFolder)

        let tempListActions: [Action?] = [
            .openMovePanel,
            unread ? .markAsUnread : .markAsRead,
            spamAction,
            isSelfThread ? nil : .phishing,
            isSelfThread || isInSpamFolder ? nil : .blockList,
            archive ? .archive : .moveToInbox,
            showUnstar ? .unstar : .star,
            .saveThreadInkDrive
        ]
        let listActions = snoozedActions + tempListActions.compactMap { $0 }

        return MessageActions(
            quickActions: Action.quickActions,
            listActions: listActions,
            euriaActions: []
        )
    }

    private func snoozedActions(_ messages: [Message], folder: Folder?) -> [Action] {
        guard folder?.canAccessSnoozeActions(featureAvailableProvider:
            featureAvailableProvider) == true else { return [] }

        let messagesFromFolder = messages.filter { $0.folder?.remoteId == folder?.remoteId }
        guard !messagesFromFolder.isEmpty else { return [] }

        if messagesFromFolder.allSatisfy(\.isSnoozed) {
            return [.modifySnooze, .cancelSnooze]
        } else {
            return [.snooze]
        }
    }

    func floatingPanelActions(origin: ActionOrigin, messages: [Message]) -> MessageActions {
        if messages.allSatisfy({ $0.isDraft }) || origin.frozenFolder?.role == .draft {
            return draftActions
        } else if messages.count == 1, let message = messages.first {
            return actionsForMessage(message, origin: origin)
        } else if messages.uniqueThreadsInFolder(origin.frozenFolder).count > 1 {
            return actionsForMessagesInDifferentThreads(messages, originFolder: origin.frozenFolder)
        } else {
            return actionsForMessagesInSameThreads(messages, originFolder: origin.frozenFolder)
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
        case .floatingPanel:
            return floatingPanelActions(origin: origin, messages: messages)
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
