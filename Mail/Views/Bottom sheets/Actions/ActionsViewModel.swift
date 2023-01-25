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
import MailCore
import MailResources
import RealmSwift

struct Action: Identifiable, Equatable {
    let id: Int
    let title: String
    let shortTitle: String?
    let icon: MailResourcesImages

    static let delete = Action(
        id: 1,
        title: MailResourcesStrings.Localizable.actionDelete,
        icon: MailResourcesAsset.bin
    )
    static let reply = Action(
        id: 2,
        title: MailResourcesStrings.Localizable.actionReply,
        icon: MailResourcesAsset.emailActionReply
    )
    static let replyAll = Action(
        id: 3,
        title: MailResourcesStrings.Localizable.actionReplyAll,
        icon: MailResourcesAsset.emailActionReplyToAll
    )
    static let archive = Action(
        id: 4,
        title: MailResourcesStrings.Localizable.actionArchive,
        icon: MailResourcesAsset.archives
    )
    static let forward = Action(
        id: 5,
        title: MailResourcesStrings.Localizable.actionForward,
        icon: MailResourcesAsset.emailActionTransfer
    )
    static let markAsRead = Action(
        id: 6,
        title: MailResourcesStrings.Localizable.actionMarkAsRead,
        shortTitle: MailResourcesStrings.Localizable.actionShortMarkAsRead,
        icon: MailResourcesAsset.envelopeOpen
    )
    static let markAsUnread = Action(
        id: 7,
        title: MailResourcesStrings.Localizable.actionMarkAsUnread,
        shortTitle: MailResourcesStrings.Localizable.actionShortMarkAsUnread,
        icon: MailResourcesAsset.envelope
    )
    static let move = Action(
        id: 8,
        title: MailResourcesStrings.Localizable.actionMove,
        icon: MailResourcesAsset.emailActionSend
    )
    static let postpone = Action(
        id: 9,
        title: MailResourcesStrings.Localizable.actionPostpone,
        icon: MailResourcesAsset.waitingMessage
    )
    static let star = Action(
        id: 10,
        title: MailResourcesStrings.Localizable.actionStar,
        shortTitle: MailResourcesStrings.Localizable.actionShortStar,
        icon: MailResourcesAsset.star
    )
    static let unstar = Action(
        id: 21,
        title: MailResourcesStrings.Localizable.actionUnstar,
        icon: MailResourcesAsset.starFull
    )
    static let spam = Action(
        id: 11,
        title: MailResourcesStrings.Localizable.actionSpam,
        icon: MailResourcesAsset.spam
    )
    static let nonSpam = Action(
        id: 20,
        title: MailResourcesStrings.Localizable.actionNonSpam,
        icon: MailResourcesAsset.spam
    )
    static let block = Action(
        id: 12,
        title: MailResourcesStrings.Localizable.actionBlockSender,
        icon: MailResourcesAsset.blockUser
    )
    static let phishing = Action(
        id: 13,
        title: MailResourcesStrings.Localizable.actionPhishing,
        icon: MailResourcesAsset.fishing
    )
    static let print = Action(
        id: 14,
        title: MailResourcesStrings.Localizable.actionPrint,
        icon: MailResourcesAsset.printText
    )
    static let saveAsPDF = Action(
        id: 15,
        title: MailResourcesStrings.Localizable.actionSavePDF,
        icon: MailResourcesAsset.fileDownload
    )
    static let createRule = Action(
        id: 16,
        title: MailResourcesStrings.Localizable.actionCreateRule,
        icon: MailResourcesAsset.ruleRegle
    )
    static let report = Action(
        id: 17,
        title: MailResourcesStrings.Localizable.actionReportDisplayProblem,
        icon: MailResourcesAsset.feedbacks
    )
    static let editMenu = Action(
        id: 18,
        title: MailResourcesStrings.Localizable.actionEditMenu,
        icon: MailResourcesAsset.editTools
    )

    init(id: Int, title: String, shortTitle: String? = nil, icon: MailResourcesImages) {
        self.id = id
        self.title = title
        self.shortTitle = shortTitle
        self.icon = icon
    }

    static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.id == rhs.id
    }
}

enum ActionsTarget: Equatable {
    case threads([Thread])
    case message(Message)

    var isInvalidated: Bool {
        switch self {
        case let .threads(threads):
            return threads.contains(where: \.isInvalidated)
        case let .message(message):
            return message.isInvalidated
        }
    }

    func freeze() -> Self {
        switch self {
        case let .threads(threads):
            return .threads(threads.map { $0.freezeIfNeeded() })
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
    private let moveSheet: MoveSheet?
    private let replyHandler: (Message, ReplyMode) -> Void
    private let completionHandler: (() -> Void)?

    @Published var quickActions: [Action] = []
    @Published var listActions: [Action] = []

    init(mailboxManager: MailboxManager,
         target: ActionsTarget,
         state: ThreadBottomSheet,
         globalSheet: GlobalBottomSheet,
         moveSheet: MoveSheet? = nil,
         replyHandler: @escaping (Message, ReplyMode) -> Void,
         completionHandler: (() -> Void)? = nil) {
        self.mailboxManager = mailboxManager
        self.target = target.freeze()
        self.state = state
        self.globalSheet = globalSheet
        self.moveSheet = moveSheet
        self.replyHandler = replyHandler
        self.completionHandler = completionHandler
        setActions()
    }

    private func setActions() {
        switch target {
        case let .threads(threads):
            if threads.count > 1 {
                let spam = threads.allSatisfy { $0.parent?.role == .spam }
                let unread = threads.allSatisfy(\.hasUnseenMessages)
                quickActions = [.move, .archive, spam ? .nonSpam : .spam, .delete]

                listActions = [
                    unread ? .markAsRead : .markAsUnread,
                    .print
                ]
            } else if let thread = threads.first {
                let replyAll = thread.messages.first?.canReplyAll ?? false
                if replyAll {
                    quickActions = [.reply, .replyAll, .forward, .delete]
                } else {
                    quickActions = [.reply, .forward, .archive, .delete]
                }

                let firstFromMe = thread.messages.first?.fromMe ?? false
                let archive = thread.messages.first?.canReplyAll ?? false
                let unread = thread.hasUnseenMessages
                let star = thread.flagged

                let spam = thread.parent?.role == .spam
                let spamAction: Action? = spam ? .nonSpam : .spam

                let tempListActions: [Action?] = [
                    archive ? .archive : nil,
                    unread ? .markAsRead : .markAsUnread,
                    .move,
                    star ? .unstar : .star,
                    firstFromMe ? nil : spamAction,
                    .print,
                    .saveAsPDF
                ]

                listActions = tempListActions.compactMap { $0 }
            }
        case let .message(message):
            if message.canReplyAll {
                quickActions = [.reply, .replyAll, .forward, .delete]
            } else {
                quickActions = [.reply, .forward, .archive, .delete]
            }

            let archive = message.canReplyAll
            let unread = !message.seen
            let star = message.flagged

            let spam = message.folderId == mailboxManager.getFolder(with: .spam)?._id
            let spamAction: Action? = spam ? .nonSpam : .spam

            let tempListActions: [Action?] = [
                archive ? .archive : nil,
                unread ? .markAsRead : .markAsUnread,
                .move,
                star ? .unstar : .star,
                message.fromMe ? nil : spamAction,
                message.fromMe ? nil : .block,
                message.fromMe ? nil : .phishing,
                .print,
                .saveAsPDF,
                .createRule,
                .report,
                .editMenu
            ]

            listActions = tempListActions.compactMap { $0 }
        }
    }

    func didTap(action: Action) async throws {
        state.close()
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
        case .saveAsPDF:
            saveAsPDF()
        case .createRule:
            createRule()
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
        case let .threads(threads):
            undoRedoAction = try await mailboxManager.move(threads: threads, to: folder)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadsMoved(folder.localizedName)
        case let .message(message):
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
        case let .threads(threads):
            try await mailboxManager.moveOrDelete(threads: threads)
        case let .message(message):
            try await mailboxManager.moveOrDelete(message: message)
        }
    }

    private func reply(mode: ReplyMode) async throws {
        var completeMode = mode
        switch target {
        case let .threads(threads):
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
            replyHandler(message, completeMode)
        case let .message(message):
            if mode == .forward([]) {
                let attachments = try await mailboxManager.apiFetcher.attachmentsToForward(
                    mailbox: mailboxManager.mailbox,
                    message: message
                ).attachments
                completeMode = .forward(attachments)
            }
            replyHandler(message, completeMode)
        }
    }

    private func archive() async throws {
        guard let archiveFolder = mailboxManager.getFolder(with: .archive)?.freeze() else { return }
        try await move(to: archiveFolder)
    }

    private func toggleRead() async throws {
        switch target {
        case let .threads(threads):
            try await mailboxManager.toggleRead(threads: threads)
        case let .message(message):
            try await mailboxManager.markAsSeen(message: message, seen: !message.seen)
        }
    }

    private func move() {
        let folderId: String?
        switch target {
        case let .threads(threads):
            folderId = threads.first?.parent?.id
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
        case let .threads(threads):
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

    private func spam() async throws {
        let undoRedoAction: UndoRedoAction
        let snackBarMessage: String
        switch target {
        case let .threads(threads):
            undoRedoAction = try await mailboxManager.reportSpam(threads: threads)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadsMoved(FolderRole.spam.localizedName)
        case let .message(message):
            var messages = [message]
            messages.append(contentsOf: message.duplicates)
            undoRedoAction = try await mailboxManager.reportSpam(messages: messages)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarMessageMoved(FolderRole.spam.localizedName)
        }

        IKSnackBar.showCancelableSnackBar(message: snackBarMessage,
                                          cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                          undoRedoAction: undoRedoAction,
                                          mailboxManager: mailboxManager)
    }

    private func nonSpam() async throws {
        let undoRedoAction: UndoRedoAction
        let snackBarMessage: String
        switch target {
        case let .threads(threads):
            undoRedoAction = try await mailboxManager.nonSpam(threads: threads)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadsMoved(FolderRole.inbox.localizedName)
        case let .message(message):
            var messages = [message]
            messages.append(contentsOf: messages.flatMap(\.duplicates))
            undoRedoAction = try await mailboxManager.nonSpam(messages: messages)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarMessageMoved(FolderRole.inbox.localizedName)
        }

        IKSnackBar.showCancelableSnackBar(message: snackBarMessage,
                                          cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                          undoRedoAction: undoRedoAction,
                                          mailboxManager: mailboxManager)
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
        globalSheet.open(state: .reportPhishing(message: message))
    }

    private func printAction() {
        // TODO: PRINT ACTION
        showWorkInProgressSnackBar()
    }

    private func saveAsPDF() {
        // TODO: SAVE AS PDF ACTION
        showWorkInProgressSnackBar()
    }

    private func createRule() {
        // TODO: CREATE RULE ACTION
        showWorkInProgressSnackBar()
    }

    private func report() {
        // This action is only available on a single message
        guard case let .message(message) = target else { return }
        globalSheet.open(state: .reportDisplayProblem(message: message))
    }

    private func editMenu() {
        // TODO: EDIT MENU ACTION
        showWorkInProgressSnackBar()
    }
}
