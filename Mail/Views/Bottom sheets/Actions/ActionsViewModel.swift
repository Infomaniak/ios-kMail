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
    let icon: MailResourcesImages

    static let delete = Action(id: 1, title: MailResourcesStrings.Localizable.actionDelete, icon: MailResourcesAsset.bin)
    static let reply = Action(id: 2, title: MailResourcesStrings.Localizable.actionReply, icon: MailResourcesAsset.emailActionReply)
    static let replyAll = Action(id: 3, title: MailResourcesStrings.Localizable.actionReplyAll, icon: MailResourcesAsset.emailActionReplyToAll)
    static let archive = Action(id: 4, title: MailResourcesStrings.Localizable.actionArchive, icon: MailResourcesAsset.archives)
    static let forward = Action(id: 5, title: MailResourcesStrings.Localizable.actionForward, icon: MailResourcesAsset.emailActionTransfer)
    static let markAsRead = Action(id: 6, title: MailResourcesStrings.Localizable.actionMarkAsRead, icon: MailResourcesAsset.envelopeOpen)
    static let markAsUnread = Action(id: 7, title: MailResourcesStrings.Localizable.actionMarkAsUnread, icon: MailResourcesAsset.envelope)
    static let move = Action(id: 8, title: MailResourcesStrings.Localizable.actionMove, icon: MailResourcesAsset.emailActionSend21)
    static let postpone = Action(id: 9, title: MailResourcesStrings.Localizable.actionPostpone, icon: MailResourcesAsset.waitingMessage)
    static let addToFavorites = Action(id: 10, title: "Ajouter en favoris", icon: MailResourcesAsset.star)
    static let deleteFromFavorites = Action(id: 21, title: "Retirer des favoris", icon: MailResourcesAsset.star)
    static let spam = Action(id: 11, title: MailResourcesStrings.Localizable.actionSpam, icon: MailResourcesAsset.spam)
    static let nonSpam = Action(id: 20, title: MailResourcesStrings.Localizable.actionNonSpam, icon: MailResourcesAsset.spam)
    static let block = Action(id: 12, title: MailResourcesStrings.Localizable.actionBlockSender, icon: MailResourcesAsset.blockUser)
    static let phishing = Action(id: 13, title: MailResourcesStrings.Localizable.actionPhishing, icon: MailResourcesAsset.fishing)
    static let print = Action(id: 14, title: MailResourcesStrings.Localizable.actionPrint, icon: MailResourcesAsset.printText)
    static let saveAsPDF = Action(id: 15, title: MailResourcesStrings.Localizable.actionSavePDF, icon: MailResourcesAsset.fileDownload)
    static let openIn = Action(id: 16, title: MailResourcesStrings.Localizable.actionOpenIn, icon: MailResourcesAsset.sendTo)
    static let createRule = Action(id: 17, title: MailResourcesStrings.Localizable.actionCreateRule, icon: MailResourcesAsset.ruleRegle)
    static let report = Action(id: 18, title: MailResourcesStrings.Localizable.actionReportDisplayProblem, icon: MailResourcesAsset.feedbacks)
    static let editMenu = Action(id: 19, title: MailResourcesStrings.Localizable.actionEditMenu, icon: MailResourcesAsset.editTools)

    static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.id == rhs.id
    }
}

enum ActionsTarget: Equatable {
    case threads([Thread])
    case thread(Thread)
    case message(Message)

    var isInvalidated: Bool {
        switch self {
        case let .threads(threads):
            return threads.contains(where: \.isInvalidated)
        case let .thread(thread):
            return thread.isInvalidated
        case let .message(message):
            return message.isInvalidated
        }
    }
}

@MainActor class ActionsViewModel: ObservableObject {
    private let mailboxManager: MailboxManager
    private let target: ActionsTarget
    private let state: ThreadBottomSheet
    private let globalSheet: GlobalBottomSheet
    private let replyHandler: (Message, ReplyMode) -> Void

    @Published var quickActions: [Action] = []
    @Published var listActions: [Action] = []

    init(mailboxManager: MailboxManager,
         target: ActionsTarget,
         state: ThreadBottomSheet,
         globalSheet: GlobalBottomSheet,
         replyHandler: @escaping (Message, ReplyMode) -> Void) {
        self.mailboxManager = mailboxManager
        self.target = target
        self.state = state
        self.globalSheet = globalSheet
        self.replyHandler = replyHandler
        setActions()
    }

    private func setActions() {
        switch target {
        case let .threads(threads):
            let spam = threads.allSatisfy { $0.parent?.role == .spam }
            quickActions = [.move, .postpone, spam ? .nonSpam : .spam, .delete]

            let unread = threads.allSatisfy { $0.unseenMessages > 0 }
            listActions = [
                .archive,
                unread ? .markAsRead : .markAsUnread,
                .print,
                .openIn
            ]
        case let .thread(thread):
            quickActions = [.reply, .replyAll, .forward, .delete]

            let unread = thread.unseenMessages > 0
            let favorites = thread.flagged
            let spam = thread.parent?.role == .spam
            listActions = [
                .archive,
                unread ? .markAsRead : .markAsUnread,
                .move,
                .postpone,
                favorites ? .deleteFromFavorites : .addToFavorites,
                spam ? .nonSpam : .spam,
                .print,
                .saveAsPDF,
                .openIn
            ]
        case let .message(message):
            quickActions = [.reply, .replyAll, .forward, .delete]

            let unread = !message.seen
            let spam = message.folderId == mailboxManager.getFolder(with: .spam)?._id
            listActions = [
                .archive,
                unread ? .markAsRead : .markAsUnread,
                .move,
                .postpone,
                spam ? .nonSpam : .spam,
                .block,
                .phishing,
                .print,
                .saveAsPDF,
                .openIn,
                .createRule,
                .report,
                .editMenu
            ]
        }
    }

    func didTap(action: Action) async throws {
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
            try await reply(mode: .forward)
        case .markAsRead, .markAsUnread:
            try await toggleRead()
        case .move:
            move()
        case .postpone:
            postpone()
        case .addToFavorites, .deleteFromFavorites:
            try await favorites()
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
        case .openIn:
            openIn()
        case .createRule:
            createRule()
        case .report:
            report()
        case .editMenu:
            editMenu()
        default:
            print("Warning: Unhandled action!")
        }
    }

    private func taskGroup(on threads: [Thread], method: @escaping (Thread) async throws -> Void) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for thread in threads {
                group.addTask {
                    try await method(thread)
                }
            }
            try await group.waitForAll()
        }
    }

    private func move(to folder: Folder) async throws {
        let response: UndoResponse
        let snackBarMessage: String
        switch target {
        case let .threads(threads):
            let messages = threads.flatMap(\.messages).map { $0.freezeIfNeeded() }
            response = try await mailboxManager.move(messages: messages, to: folder)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadsMoved(folder.localizedName)
        case let .thread(thread):
            response = try await mailboxManager.move(thread: thread.freezeIfNeeded(), to: folder)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadMoved(folder.localizedName)
        case let .message(message):
            response = try await mailboxManager.move(messages: [message.freezeIfNeeded()], to: folder)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarMessageMoved(folder.localizedName)
        }

        IKSnackBar.showCancelableSnackBar(message: snackBarMessage,
                                          cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                          cancelableResponse: response,
                                          mailboxManager: mailboxManager)
    }

    // MARK: - Actions methods

    private func delete() async throws {
        switch target {
        case let .threads(threads):
            try await taskGroup(on: threads, method: mailboxManager.moveOrDelete)
        case let .thread(thread):
            try await mailboxManager.moveOrDelete(thread: thread.freezeIfNeeded())
        case let .message(message):
            if message.folderId == mailboxManager.getFolder(with: .trash)?._id {
                // Delete definitely
                try await mailboxManager.delete(messages: [message.freezeIfNeeded()])
            } else if message.isDraft && message.uid.starts(with: Draft.uuidLocalPrefix) {
                // Delete local draft from Realm
                if let thread = message.parent {
                    mailboxManager.deleteLocalDraft(thread: thread)
                }
            } else {
                // Move to trash
                let response = try await mailboxManager.move(messages: [message.freezeIfNeeded()], to: .trash)
                IKSnackBar.showCancelableSnackBar(
                    message: MailResourcesStrings.Localizable.snackbarMessageMoved(FolderRole.trash.localizedName),
                    cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                    cancelableResponse: response,
                    mailboxManager: mailboxManager
                )
            }
        }
        state.close()
    }

    private func reply(mode: ReplyMode) async throws {
        switch target {
        case .threads:
            // We don't handle this action in multiple selection
            break
        case let .thread(thread):
            guard let message = thread.messages.last(where: { !$0.isDraft }) else { return }
            // Download message if needed to get body
            if !message.fullyDownloaded {
                try await mailboxManager.message(message: message)
            }
            message.realm?.refresh()
            replyHandler(message, mode)
        case let .message(message):
            replyHandler(message, mode)
        }
    }

    private func archive() async throws {
        guard let archiveFolder = mailboxManager.getFolder(with: .archive)?.freeze() else { return }
        try await move(to: archiveFolder)
    }

    private func toggleRead() async throws {
        switch target {
        case let .threads(threads):
            try await taskGroup(on: threads, method: mailboxManager.toggleRead)
        case let .thread(thread):
            try await mailboxManager.toggleRead(thread: thread.freezeIfNeeded())
        case let .message(message):
            try await mailboxManager.markAsSeen(messages: [message.freezeIfNeeded()], seen: !message.seen)
        }
    }

    private func move() {
        state.close()
        globalSheet.open(state: .move { folder in
            Task {
                try await self.move(to: folder)
            }
        }, position: .moveHeight)
    }

    private func postpone() {
        // TODO: POSTPONE ACTION
        showWorkInProgressSnackBar()
    }

    private func favorites() async throws {
        switch target {
        case let .thread(thread):
            Task {
                await tryOrDisplayError {
                    try await mailboxManager.toggleStar(thread: thread.freezeIfNeeded())
                }
            }
        default:
            break
        }
    }

    private func spam() async throws {
        let response: UndoResponse
        let snackBarMessage: String
        switch target {
        case let .threads(threads):
            response = try await mailboxManager.reportSpam(messages: threads.flatMap(\.messages).map { $0.freezeIfNeeded() })
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadsMoved(FolderRole.spam.localizedName)
        case let .thread(thread):
            response = try await mailboxManager.reportSpam(thread: thread.freezeIfNeeded())
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadMoved(FolderRole.spam.localizedName)
        case let .message(message):
            response = try await mailboxManager.reportSpam(messages: [message.freezeIfNeeded()])
            snackBarMessage = MailResourcesStrings.Localizable.snackbarMessageMoved(FolderRole.spam.localizedName)
        }

        IKSnackBar.showCancelableSnackBar(message: snackBarMessage,
                                          cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                          cancelableResponse: response,
                                          mailboxManager: mailboxManager)
    }

    private func nonSpam() async throws {
        let response: UndoResponse
        let snackBarMessage: String
        switch target {
        case let .threads(threads):
            response = try await mailboxManager.nonSpam(messages: threads.flatMap(\.messages).map { $0.freezeIfNeeded() })
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadsMoved(FolderRole.inbox.localizedName)
        case let .thread(thread):
            response = try await mailboxManager.nonSpam(thread: thread.freezeIfNeeded())
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadMoved(FolderRole.inbox.localizedName)
        case let .message(message):
            response = try await mailboxManager.nonSpam(messages: [message.freezeIfNeeded()])
            snackBarMessage = MailResourcesStrings.Localizable.snackbarMessageMoved(FolderRole.inbox.localizedName)
        }

        IKSnackBar.showCancelableSnackBar(message: snackBarMessage,
                                          cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                          cancelableResponse: response,
                                          mailboxManager: mailboxManager)
    }

    private func block() async throws {
        // This action is only available on a single message
        guard case let .message(message) = target else { return }
        let response = try await mailboxManager.apiFetcher.blockSender(message: message.freezeIfNeeded())
        if response {
            IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackbarSenderBlacklisted)
        }
    }

    private func phishing() async throws {
        // This action is only available on a single message
        guard case let .message(message) = target else { return }
        state.close()
        globalSheet.open(state: .reportPhishing(message: message.freezeIfNeeded()), position: .reportPhishingHeight)
    }

    private func printAction() {
        // TODO: PRINT ACTION
        showWorkInProgressSnackBar()
    }

    private func saveAsPDF() {
        // TODO: SAVE AS PDF ACTION
        showWorkInProgressSnackBar()
    }

    private func openIn() {
        // TODO: OPEN IN ACTION
        showWorkInProgressSnackBar()
    }

    private func createRule() {
        // TODO: CREATE RULE ACTION
        showWorkInProgressSnackBar()
    }

    private func report() {
        // This action is only available on a single message
        guard case let .message(message) = target else { return }
        state.close()
        globalSheet.open(state: .reportDisplayProblem(message: message.freezeIfNeeded()), position: .reportDisplayIssueHeight)
    }

    private func editMenu() {
        // TODO: EDIT MENU ACTION
        showWorkInProgressSnackBar()
    }
}
