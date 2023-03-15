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
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift

struct Action: Identifiable, Equatable {
    let id: Int
    let title: String
    let shortTitle: String?
    let icon: MailResourcesImages
    let matomoName: String?

    static let delete = Action(
        id: 1,
        title: MailResourcesStrings.Localizable.actionDelete,
        icon: MailResourcesAsset.bin,
        matomoName: "delete"
    )
    static let reply = Action(
        id: 2,
        title: MailResourcesStrings.Localizable.actionReply,
        icon: MailResourcesAsset.emailActionReply,
        matomoName: "reply"
    )
    static let replyAll = Action(
        id: 3,
        title: MailResourcesStrings.Localizable.actionReplyAll,
        icon: MailResourcesAsset.emailActionReplyToAll,
        matomoName: "replyAll"
    )
    static let archive = Action(
        id: 4,
        title: MailResourcesStrings.Localizable.actionArchive,
        icon: MailResourcesAsset.archives,
        matomoName: "archive"
    )
    static let forward = Action(
        id: 5,
        title: MailResourcesStrings.Localizable.actionForward,
        icon: MailResourcesAsset.emailActionTransfer,
        matomoName: "forward"
    )
    static let markAsRead = Action(
        id: 6,
        title: MailResourcesStrings.Localizable.actionMarkAsRead,
        shortTitle: MailResourcesStrings.Localizable.actionShortMarkAsRead,
        icon: MailResourcesAsset.envelopeOpen,
        matomoName: "markAsSeen"
    )
    static let markAsUnread = Action(
        id: 7,
        title: MailResourcesStrings.Localizable.actionMarkAsUnread,
        shortTitle: MailResourcesStrings.Localizable.actionShortMarkAsUnread,
        icon: MailResourcesAsset.envelope,
        matomoName: "markAsSeen"
    )
    static let move = Action(
        id: 8,
        title: MailResourcesStrings.Localizable.actionMove,
        icon: MailResourcesAsset.emailActionSend,
        matomoName: "move"
    )
    static let postpone = Action(
        id: 9,
        title: MailResourcesStrings.Localizable.actionPostpone,
        icon: MailResourcesAsset.waitingMessage,
        matomoName: "postpone"
    )
    static let star = Action(
        id: 10,
        title: MailResourcesStrings.Localizable.actionStar,
        shortTitle: MailResourcesStrings.Localizable.actionShortStar,
        icon: MailResourcesAsset.star,
        matomoName: "favorite"
    )
    static let unstar = Action(
        id: 21,
        title: MailResourcesStrings.Localizable.actionUnstar,
        icon: MailResourcesAsset.unstar,
        matomoName: "favorite"
    )
    static let reportJunk = Action(
        id: 22,
        title: MailResourcesStrings.Localizable.actionReportJunk,
        icon: MailResourcesAsset.report,
        matomoName: nil
    )
    static let spam = Action(
        id: 11,
        title: MailResourcesStrings.Localizable.actionSpam,
        icon: MailResourcesAsset.spam,
        matomoName: "spam"
    )
    static let nonSpam = Action(
        id: 20,
        title: MailResourcesStrings.Localizable.actionNonSpam,
        icon: MailResourcesAsset.spam,
        matomoName: "spam"
    )
    static let block = Action(
        id: 12,
        title: MailResourcesStrings.Localizable.actionBlockSender,
        icon: MailResourcesAsset.blockUser,
        matomoName: "blockUser"
    )
    static let phishing = Action(
        id: 13,
        title: MailResourcesStrings.Localizable.actionPhishing,
        icon: MailResourcesAsset.phishing,
        matomoName: "signalPhishing"
    )
    static let print = Action(
        id: 14,
        title: MailResourcesStrings.Localizable.actionPrint,
        icon: MailResourcesAsset.printText,
        matomoName: "print"
    )
    static let report = Action(
        id: 15,
        title: MailResourcesStrings.Localizable.actionReportDisplayProblem,
        icon: MailResourcesAsset.feedbacks,
        matomoName: nil
    )
    static let editMenu = Action(
        id: 16,
        title: MailResourcesStrings.Localizable.actionEditMenu,
        icon: MailResourcesAsset.editTools,
        matomoName: "editMenu"
    )
    static let moveToInbox = Action(
        id: 17,
        title: MailResourcesStrings.Localizable.actionMoveToInbox,
        icon: MailResourcesAsset.drawer
    )

    static let quickActions: [Action] = [.reply, .replyAll, .forward, .delete]

    init(id: Int, title: String, shortTitle: String? = nil, icon: MailResourcesImages, matomoName: String?) {
        self.id = id
        self.title = title
        self.shortTitle = shortTitle
        self.icon = icon
        self.matomoName = matomoName
    }

    static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.id == rhs.id
    }
}

enum ActionsTarget: Equatable {
    case threads([Thread], Bool)
    case message(Message)

    var isInvalidated: Bool {
        switch self {
        case let .threads(threads, _):
            return threads.contains(where: \.isInvalidated)
        case let .message(message):
            return message.isInvalidated
        }
    }

    func freeze() -> Self {
        switch self {
        case let .threads(threads, isMultiSelectionEnabled):
            return .threads(threads.map { $0.freezeIfNeeded() }, isMultiSelectionEnabled)
        case let .message(message):
            return .message(message.freezeIfNeeded())
        }
    }
}

@MainActor class ActionsViewModel: ObservableObject {
    private let mailboxManager: MailboxManager
    private let target: ActionsTarget
    private let state: ThreadBottomSheet
    private let globalSheet: GlobalBottomSheet
    private let globalAlert: GlobalAlert?
    private let moveSheet: MoveSheet?
    private let replyHandler: ((Message, ReplyMode) -> Void)?
    private let completionHandler: (() -> Void)?

    private let matomoCategory: MatomoUtils.EventCategory?

    @Published var quickActions: [Action] = []
    @Published var listActions: [Action] = []

    @LazyInjectService private var matomo: MatomoUtils

    init(mailboxManager: MailboxManager,
         target: ActionsTarget,
         state: ThreadBottomSheet,
         globalSheet: GlobalBottomSheet,
         globalAlert: GlobalAlert? = nil,
         moveSheet: MoveSheet? = nil,
         matomoCategory: MatomoUtils.EventCategory? = nil,
         replyHandler: ((Message, ReplyMode) -> Void)? = nil,
         completionHandler: (() -> Void)? = nil) {
        self.mailboxManager = mailboxManager
        self.target = target.freeze()
        self.state = state
        self.globalSheet = globalSheet
        self.globalAlert = globalAlert
        self.moveSheet = moveSheet
        self.replyHandler = replyHandler
        self.completionHandler = completionHandler
        self.matomoCategory = matomoCategory
        setActions()
    }

    private func setActions() {
        switch target {
        case let .threads(threads, _):
            if threads.count > 1 {
                let spam = threads.allSatisfy { $0.folder?.role == .spam }
                let unread = threads.allSatisfy(\.hasUnseenMessages)
                quickActions = Action.quickActions

                listActions = [
                    unread ? .markAsRead : .markAsUnread,
                    .print
                ]
            } else if let thread = threads.first {
                quickActions = Action.quickActions

                let archive = thread.folder?.role != .archive
                let unread = thread.hasUnseenMessages
                let star = thread.flagged

                let spam = thread.folder?.role == .spam
                let spamAction: Action? = spam ? .nonSpam : .spam

                let tempListActions: [Action?] = [
                    archive ? .archive : .moveToInbox,
                    unread ? .markAsRead : .markAsUnread,
                    .move,
                    star ? .unstar : .star,
                    spamAction,
                    .print
                ]

                listActions = tempListActions.compactMap { $0 }
            }
        case let .message(message):
            quickActions = [.reply, .replyAll, .forward, .delete]

            let archive = message.folder?.role != .archive
            let unread = !message.seen
            let star = message.flagged
            let isStaff = AccountManager.instance.currentAccount?.user?.isStaff ?? false
            let tempListActions: [Action?] = [
                archive ? .archive : .moveToInbox,
                unread ? .markAsRead : .markAsUnread,
                .move,
                star ? .unstar : .star,
                .reportJunk,
                .print,
                isStaff ? .report : nil
            ]

            listActions = tempListActions.compactMap { $0 }
        }
    }

    func didTap(action: Action) async throws {
        state.close()
        globalSheet.close()
        if let matomoCategory, let matomoName = action.matomoName {
            if case let .threads(threads, isMultipleSelectionEnabled) = target, isMultipleSelectionEnabled {
                matomo.trackBulkEvent(eventWithCategory: matomoCategory, name: matomoName, numberOfItems: threads.count)
            } else {
                matomo.track(eventWithCategory: matomoCategory, name: matomoName)
            }
        }
        switch action {
        case .delete:
            try await delete()
        case .reply:
            try await reply(mode: .reply)
        case .replyAll:
            try await reply(mode: .replyAll)
        case .archive:
            try await archive()
        case .forward:
            try await reply(mode: .forward([]))
        case .markAsRead, .markAsUnread:
            try await toggleRead()
        case .move:
            move()
        case .postpone:
            postpone()
        case .star, .unstar:
            try await star()
        case .reportJunk:
            displayReportJunk()
        case .spam:
            try await spam()
        case .nonSpam:
            try await nonSpam()
        case .block:
            try await block()
        case .phishing:
            try await phishing()
        case .print:
            printAction()
        case .report:
            report()
        case .editMenu:
            editMenu()
        default:
            print("Warning: Unhandled action!")
        }
        completionHandler?()
    }

    private func move(to folder: Folder) async throws {
        let undoRedoAction: UndoRedoAction
        let snackBarMessage: String
        switch target {
        case let .threads(threads, _):
            guard threads.first?.folder != folder else { return }
            undoRedoAction = try await mailboxManager.move(threads: threads, to: folder)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadsMoved(folder.localizedName)
        case let .message(message):
            guard message.folderId != folder.id else { return }
            var messages = [message]
            messages.append(contentsOf: message.duplicates)
            undoRedoAction = try await mailboxManager.move(messages: messages, to: folder)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarMessageMoved(folder.localizedName)
        }

        IKSnackBar.showCancelableSnackBar(message: snackBarMessage,
                                          cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                          undoRedoAction: undoRedoAction,
                                          mailboxManager: mailboxManager)
    }

    // MARK: - Actions methods

    private func delete() async throws {
        switch target {
        case let .threads(threads, _):
            try await mailboxManager.moveOrDelete(threads: threads)
        case let .message(message):
            try await mailboxManager.moveOrDelete(message: message)
        }
    }

    private func reply(mode: ReplyMode) async throws {
        var completeMode = mode
        switch target {
        case let .threads(threads, _):
            // We don't handle this action in multiple selection
            guard threads.count == 1, let thread = threads.first,
                  let message = thread.messages.last(where: { !$0.isDraft }) else { break }
            // Download message if needed to get body
            if !message.fullyDownloaded {
                try await mailboxManager.message(message: message)
            }
            if mode == .forward([]) {
                let attachments = try await mailboxManager.apiFetcher.attachmentsToForward(
                    mailbox: mailboxManager.mailbox,
                    message: message
                ).attachments
                completeMode = .forward(attachments)
            }
            replyHandler?(message, completeMode)
        case let .message(message):
            if mode == .forward([]) {
                let attachments = try await mailboxManager.apiFetcher.attachmentsToForward(
                    mailbox: mailboxManager.mailbox,
                    message: message
                ).attachments
                completeMode = .forward(attachments)
            }
            replyHandler?(message, completeMode)
        }
    }

    private func archive() async throws {
        guard let archiveFolder = mailboxManager.getFolder(with: .archive)?.freeze() else { return }
        try await move(to: archiveFolder)
    }

    private func toggleRead() async throws {
        switch target {
        case let .threads(threads, _):
            try await mailboxManager.toggleRead(threads: threads)
        case let .message(message):
            try await mailboxManager.markAsSeen(message: message, seen: !message.seen)
        }
    }

    private func move() {
        let folderId: String?
        switch target {
        case let .threads(threads, _):
            folderId = threads.first?.folder?.id
        case let .message(message):
            folderId = message.folderId
        }

        moveSheet?.state = .move(folderId: folderId) { folder in
            Task {
                try await self.move(to: folder)
            }
        }
    }

    private func postpone() {
        // TODO: POSTPONE ACTION
        showWorkInProgressSnackBar()
    }

    private func star() async throws {
        switch target {
        case let .threads(threads, _):
            await tryOrDisplayError {
                try await mailboxManager.toggleStar(threads: threads)
            }
        case let .message(message):
            await tryOrDisplayError {
                if message.flagged {
                    _ = try await mailboxManager.unstar(messages: [message])
                } else {
                    _ = try await mailboxManager.star(messages: [message])
                }
            }
        }
    }

    private func displayReportJunk() {
        globalSheet.open(state: .reportJunk(threadBottomSheet: state, target: target))
    }

    private func spam() async throws {
        guard let spamFolder = mailboxManager.getFolder(with: .spam)?.freeze() else { return }
        try await move(to: spamFolder)
    }

    private func nonSpam() async throws {
        guard let inboxFolder = mailboxManager.getFolder(with: .inbox)?.freeze() else { return }
        try await move(to: inboxFolder)
    }

    private func block() async throws {
        // This action is only available on a single message
        guard case let .message(message) = target else { return }
        let response = try await mailboxManager.apiFetcher.blockSender(message: message)
        if response {
            IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackbarSenderBlacklisted)
        }
    }

    private func phishing() async throws {
        // This action is only available on a single message
        guard case let .message(message) = target else { return }
        globalAlert?.state = .reportPhishing(message: message)
    }

    private func printAction() {
        // TODO: PRINT ACTION
        showWorkInProgressSnackBar()
    }

    private func report() {
        // This action is only available on a single message
        guard case let .message(message) = target else { return }
        globalAlert?.state = .reportDisplayProblem(message: message)
    }

    private func editMenu() {
        // TODO: EDIT MENU ACTION
        showWorkInProgressSnackBar()
    }
}
