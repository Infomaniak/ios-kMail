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
    enum ToolbarActions {
        static let standardActions: [Action] = [.reply, .forward, .archive, .delete]
        static let archiveActions: [Action] = [.reply, .forward, .openMovePanel, .delete]
        static let scheduleActions: [Action] = [.delete]
    }

    let currentUser: UserProfile
    let currentEmail: String
    let featureAvailableProvider: FeatureAvailableProvider
    let threadViewState: ThreadViewState
    let colorScheme: ColorScheme

    private var swipeFullLeading: Action {
        UserDefaults.shared.swipeFullLeading
    }

    private var swipeLeading: Action {
        UserDefaults.shared.swipeLeading
    }

    private var swipeFullTrailing: Action {
        UserDefaults.shared.swipeFullTrailing
    }

    private var swipeTrailing: Action {
        UserDefaults.shared.swipeTrailing
    }

    public init(
        currentUser: UserProfile,
        featureAvailableProvider: FeatureAvailableProvider,
        currentEmail: String,
        threadViewState: ThreadViewState,
        colorScheme: ColorScheme
    ) {
        self.currentUser = currentUser
        self.currentEmail = currentEmail
        self.featureAvailableProvider = featureAvailableProvider
        self.threadViewState = threadViewState
        self.colorScheme = colorScheme
    }

    public let rightClickActions: [Action] = [
        .activeMultiselect,
        .reply,
        .replyAll,
        .forward,
        .openMovePanel,
        .archive,
        .delete
    ]

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

    public func allAvailableSwipeActions() -> [Action] {
        let hasAccessToSnoozeFeature = featureAvailableProvider.isAvailable(.snooze)

        let actions: [Action?] = [
            .delete,
            .archive,
            .markAsRead,
            .openMovePanel,
            .star,
            hasAccessToSnoozeFeature ? .snooze : nil,
            .spam,
            .quickActionPanel,
            .noAction
        ]
        return actions.compactMap { $0 }
    }

    private let draftActions: [Action] = [.shareMailLink, .saveThreadInkDrive]

    private let quickActions: [Action] = [.reply, .replyAll, .forward, .delete]

    private func isSelfThread(_ messages: [Message]) -> Bool {
        return messages.flatMap(\.from).allSatisfy { $0.isMe(currentMailboxEmail: currentEmail) }
    }

    private func euriaActionsForMessage() -> [Action] {
        let translate = featureAvailableProvider.isAvailable(.translate)
        let summarize = featureAvailableProvider.isAvailable(.summarize)

        let tempEuriaActions: [Action?] = [
            summarize ? .summarize : nil,
            translate ? .translateMessage : nil
        ]
        let euriaActions = tempEuriaActions.compactMap { $0 }

        return euriaActions
    }

    private func actionsForMessage(_ message: Message, origin: ActionOrigin) -> [Action] {
        @LazyInjectService var platformDetector: PlatformDetectable

        let snoozedActions = snoozedActions([message], folder: origin.frozenFolder)
        let euriaActions = euriaActionsForMessage()

        let isFromMe = message.fromMe(currentMailboxEmail: currentEmail)
        let isInSpamFolder = message.folder?.role == .spam
        var spamAction: Action? {
            guard !isFromMe else { return nil }
            return isInSpamFolder ? .nonSpam : .spam
        }
        let archive = message.folder?.role != .archive
        let unread = !message.seen
        let star = message.flagged
        let print = origin.type == .floatingPanelListAction(source: .message)
        let showEuriaActions = !euriaActions.isEmpty && origin.type == .floatingPanelListAction(source: .message)
        var tempListActions: [Action?] = [
            showEuriaActions ? .showEuriaActions : nil,
            .openMovePanel,
            unread ? .markAsRead : .markAsUnread,
            spamAction,
            isFromMe ? nil : .phishing,
            isFromMe || isInSpamFolder ? nil : .blockList,
            .shareMailLink,
            archive ? .archive : .moveToInbox,
            star ? .unstar : .star,
            print ? .print : nil,
            themeAction(message: message),
            platformDetector.isMac ? nil : .saveThreadInkDrive,
            currentUser.isStaff == true ? .reportDisplayProblem : nil
        ]

        if message.isScheduledDraft == true {
            tempListActions.removeAll { $0 == .archive }
        }

        let listActions = snoozedActions + tempListActions.compactMap { $0 }

        return listActions
    }

    private func actionsForMessagesInDifferentThreads(_ messages: [Message], originFolder: Folder?) -> [Action] {
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
        }

        let listActions = snoozedActions + tempListActions.compactMap { $0 }

        return listActions
    }

    private func actionsForMessagesInSameThreads(_ messages: [Message],
                                                 originFolder: Folder?)
        -> [Action] {
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

        return listActions
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

    private func themeAction(message: Message) -> Action? {
        guard colorScheme == .dark else { return nil }
        if threadViewState.forcedLightModes.contains(where: { $0 == message.uid }) {
            return .forceDarkMode
        } else {
            return .forceLightMode
        }
    }

    func floatingPanelListActions(origin: ActionOrigin, messages: [Message]) -> [Action] {
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

    func floatingPanelQuickActions(origin: ActionOrigin, messages: [Message]) -> [Action] {
        if messages.allSatisfy({ $0.isDraft }) || origin.frozenFolder?.role == .draft {
            return []
        }

        let isSingleThread = messages.uniqueThreadsInFolder(origin.frozenFolder).count == 1

        if origin.type == .floatingPanelQuickAction(source: .message) || isSingleThread {
            return quickActions
        }

        return [
            .openMovePanel,
            messages.allSatisfy(\.seen) ? .markAsUnread : .markAsRead,
            origin.frozenFolder?.role == .archive ? .moveToInbox : .archive,
            .delete
        ]
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

    func largeToolbarActions(mode: ActionOrigin.ToolbarMode, messages: [Message], folder: Folder, thread: Thread) -> [Action] {
        if case .large(let group) = mode {
            switch group {
            case .move:
                return [.snooze, folder.role == .archive ? .moveToInbox : .archive, .openMovePanel, .delete]
            case .reply:
                return [.reply, .forward, .replyAll]
            case .report:
                return [.blockList, folder.role == .spam ? .nonSpam : .spam, .phishing]
            case .other:
                let isRead = messages.allSatisfy { $0.seen }
                let canUseEuriaActions = (messages.count == 1 &&
                    (featureAvailableProvider.isAvailable(.summarize) ||
                        featureAvailableProvider.isAvailable(.translate)))

                var actions: [Action] = [isRead ? .markAsUnread : .markAsRead,
                                         thread.flagged ? .unstar : .star]

                if canUseEuriaActions {
                    actions.append(.showEuriaActions)
                }

                actions.append(.saveThreadInkDrive)

                return actions
            }
        }
        return []
    }

    func toolbarActions(origin: ActionOrigin, messages: [Message]) -> [Action] {
        guard let folder = origin.frozenFolder else { return [] }
        if case .toolbar(let mode) = origin.type {
            if mode == .compact {
                return compactToolbarActions(for: messages, folder: folder)
            } else {
                guard let thread = origin.thread else { return [] }
                if thread.containsOnlyScheduledDrafts == true {
                    return [.delete]
                }
                return largeToolbarActions(mode: mode, messages: messages, folder: folder, thread: thread)
            }
        }
        return []
    }

    func multipleSelectionActions(origin: ActionOrigin, messages: [Message]) -> [Action] {
        let lastMessages = messages.lastMessagesAndDuplicatesToExecuteAction(
            currentMailboxEmail: currentEmail,
            currentFolder: origin.frozenFolder,
            featureAvailableProvider: featureAvailableProvider
        )
        let fromArchiveFolder = origin.frozenFolder?.role == .archive
        let read = messages.contains { !$0.seen } ? Action.markAsRead : Action.markAsUnread
        let star = lastMessages.allSatisfy { $0.flagged } ? Action.unstar : Action.star
        let archive = fromArchiveFolder ? Action.openMovePanel : Action.archive
        return [read, archive, star, .delete]
    }

    func shortcutActions() -> [Action] {
        return [.delete, .deleteShortcut, .reply, .refresh, .writeEmailAction]
    }

    public func actionsFor(origin: ActionOrigin, messages: [Message]) -> [Action] {
        switch origin.type {
        case .swipe:
            return swipeActions(origin: origin)
        case .floatingPanelListAction:
            return floatingPanelListActions(origin: origin, messages: messages)
        case .floatingPanelQuickAction:
            return floatingPanelQuickActions(origin: origin, messages: messages)
        case .euriaActions:
            return euriaActionsForMessage()
        case .toolbar:
            return toolbarActions(origin: origin, messages: messages)
        case .multipleSelection:
            return multipleSelectionActions(origin: origin, messages: messages)
        case .shortcut:
            return shortcutActions()
        case .threadHeader:
            return []
        }
    }
}
