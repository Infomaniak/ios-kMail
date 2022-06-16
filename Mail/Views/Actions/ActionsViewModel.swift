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

    static let delete = Action(id: 1, title: MailResourcesStrings.buttonDelete, icon: MailResourcesAsset.bin)
    static let reply = Action(id: 2, title: MailResourcesStrings.buttonReply, icon: MailResourcesAsset.emailActionReply)
    static let replyAll = Action(id: 3, title: MailResourcesStrings.buttonReplyAll, icon: MailResourcesAsset.emailActionReplyToAll)
    static let archive = Action(id: 4, title: MailResourcesStrings.buttonArchive, icon: MailResourcesAsset.archives)
    static let forward = Action(id: 5, title: MailResourcesStrings.buttonForward, icon: MailResourcesAsset.emailActionTransfer)
    static let markAsRead = Action(id: 6, title: MailResourcesStrings.buttonMarkAsRead, icon: MailResourcesAsset.envelope)
    static let markAsUnread = Action(id: 7, title: MailResourcesStrings.buttonMarkAsUnread, icon: MailResourcesAsset.envelopeOpen)
    static let move = Action(id: 8, title: MailResourcesStrings.buttonMove, icon: MailResourcesAsset.emailActionSend21)
    static let postpone = Action(id: 9, title: MailResourcesStrings.buttonPostpone, icon: MailResourcesAsset.waitingMessage)
    static let spam = Action(id: 10, title: MailResourcesStrings.buttonSpam, icon: MailResourcesAsset.spam)
    static let block = Action(id: 11, title: MailResourcesStrings.buttonBlockSender, icon: MailResourcesAsset.blockUser)
    static let phishing = Action(id: 12, title: MailResourcesStrings.buttonPhishing, icon: MailResourcesAsset.fishing)
    static let print = Action(id: 13, title: MailResourcesStrings.buttonPrint, icon: MailResourcesAsset.printText)
    static let saveAsPDF = Action(id: 14, title: MailResourcesStrings.buttonSavePDF, icon: MailResourcesAsset.fileDownload)
    static let openIn = Action(id: 15, title: MailResourcesStrings.buttonOpenIn, icon: MailResourcesAsset.sendTo)
    static let createRule = Action(id: 16, title: MailResourcesStrings.buttonCreateRule, icon: MailResourcesAsset.ruleRegle)
    static let report = Action(id: 17, title: MailResourcesStrings.buttonReportDisplayProblem, icon: MailResourcesAsset.feedbacks)
    static let editMenu = Action(id: 18, title: MailResourcesStrings.buttonEditMenu, icon: MailResourcesAsset.editTools)

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
        case .threads(let threads):
            return threads.contains(where: \.isInvalidated)
        case .thread(let thread):
            return thread.isInvalidated
        case .message(let message):
            return message.isInvalidated
        }
    }
}

@MainActor class ActionsViewModel: ObservableObject {
    private let mailboxManager: MailboxManager
    private let target: ActionsTarget
    private let state: ThreadBottomSheet
    private let replyHandler: (Message, ReplyMode) -> Void

    @Published var quickActions: [Action] = []
    @Published var listActions: [Action] = []

    init(mailboxManager: MailboxManager,
         target: ActionsTarget,
         state: ThreadBottomSheet,
         replyHandler: @escaping (Message, ReplyMode) -> Void) {
        self.mailboxManager = mailboxManager
        self.target = target
        self.state = state
        self.replyHandler = replyHandler
        setActions()
    }

    private func setActions() {
        // In the future, we might want to adjust the actions based on the target
        quickActions = [.reply, .replyAll, .forward, .delete]
        let unread: Bool
        switch target {
        case .threads(let threads):
            unread = threads.allSatisfy { $0.unseenMessages > 0 }
        case .thread(let thread):
            unread = thread.unseenMessages > 0
        case .message(let message):
            unread = !message.seen
        }
        listActions = [
            .archive,
            unread ? .markAsRead : .markAsUnread,
            .move,
            .postpone,
            .spam,
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

    func didTap(action: Action) {
        switch action {
        case .delete:
            Task {
                try await delete()
            }
        case .reply:
            Task {
                try await reply(mode: .reply)
            }
        case .replyAll:
            Task {
                try await reply(mode: .replyAll)
            }
        case .archive:
            Task {
                try await archive()
            }
        case .forward:
            Task {
                try await reply(mode: .forward)
            }
        case .markAsRead, .markAsUnread:
            Task {
                try await toggleRead()
            }
        case .move:
            move()
        case .postpone:
            postpone()
        case .spam:
            Task {
                try await spam()
            }
        case .block:
            block()
        case .phishing:
            phishing()
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

    // MARK: - Actions methods

    private func delete() async throws {
        switch target {
        case .threads(let threads):
            try await taskGroup(on: threads, method: mailboxManager.moveOrDelete)
        case .thread(let thread):
            try await mailboxManager.moveOrDelete(thread: thread.freezeIfNeeded())
        case .message(let message):
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
                try await mailboxManager.move(messages: [message.freezeIfNeeded()], to: .trash)
            }
        }
        state.close()
    }

    private func reply(mode: ReplyMode) async throws {
        switch target {
        case .threads:
            // We don't handle this action in multiple selection
            break
        case .thread(let thread):
            guard let message = thread.messages.last(where: { !$0.isDraft }) else { return }
            // Download message if needed to get body
            if !message.fullyDownloaded {
                try await mailboxManager.message(message: message)
            }
            message.realm?.refresh()
            replyHandler(message, mode)
        case .message(let message):
            replyHandler(message, mode)
        }
    }

    private func archive() async throws {
        switch target {
        case .threads(let threads):
            try await taskGroup(on: threads) { [mailboxManager] thread in
                try await mailboxManager.move(thread: thread, to: .archive)
            }
        case .thread(let thread):
            try await mailboxManager.move(thread: thread.freezeIfNeeded(), to: .archive)
        case .message(let message):
            try await mailboxManager.move(messages: [message.freezeIfNeeded()], to: .archive)
        }
    }

    private func toggleRead() async throws {
        switch target {
        case .threads(let threads):
            try await taskGroup(on: threads, method: mailboxManager.toggleRead)
        case .thread(let thread):
            try await mailboxManager.toggleRead(thread: thread.freezeIfNeeded())
        case .message(let message):
            try await mailboxManager.markAsSeen(messages: [message.freezeIfNeeded()], seen: !message.seen)
        }
    }

    private func move() {
        print("MOVE ACTION")
    }

    private func postpone() {
        print("POSTPONE ACTION")
    }

    private func spam() async throws {
        let response: UndoResponse
        switch target {
        case .threads(let threads):
            response = try await mailboxManager.reportSpam(messages: threads.flatMap(\.messages).map { $0.freezeIfNeeded() })
        case .thread(let thread):
            response = try await mailboxManager.reportSpam(thread: thread.freezeIfNeeded())
        case .message(let message):
            response = try await mailboxManager.reportSpam(messages: [message.freezeIfNeeded()])
        }

        IKSnackBar.showCancelableSnackBar(message: "Conversation déplacée vers Spam",
                                          cancelSuccessMessage: "Déplacement annulé",
                                          cancelableResponse: response,
                                          mailboxManager: mailboxManager)
    }

    private func block() {
        print("BLOCK ACTION")
    }

    private func phishing() {
        print("PHISHING ACTION")
    }

    private func printAction() {
        print("PRINT ACTION")
    }

    private func saveAsPDF() {
        print("SAVE AS PDF ACTION")
    }

    private func openIn() {
        print("OPEN IN ACTION")
    }

    private func createRule() {
        print("CREATE RULE ACTION")
    }

    private func report() {
        print("REPORT ACTION")
    }

    private func editMenu() {
        print("EDIT MENU ACTION")
    }
}
