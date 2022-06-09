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
import MailCore
import MailResources
import RealmSwift

struct Action: Identifiable, Equatable {
    let id: Int
    let title: String
    let icon: MailResourcesImages

    static let delete = Action(id: 1, title: MailResourcesStrings.buttonDelete, icon: MailResourcesAsset.bin)
    static let reply = Action(id: 2, title: MailResourcesStrings.buttonReply, icon: MailResourcesAsset.emailActionReply)
    static let archive = Action(id: 3, title: MailResourcesStrings.buttonArchive, icon: MailResourcesAsset.archives)
    static let forward = Action(id: 4, title: MailResourcesStrings.buttonForward, icon: MailResourcesAsset.emailActionTransfer)
    static let markAsRead = Action(id: 5, title: MailResourcesStrings.buttonMarkAsRead, icon: MailResourcesAsset.envelope)
    static let markAsUnread = Action(id: 17, title: MailResourcesStrings.buttonMarkAsUnread, icon: MailResourcesAsset.envelopeOpen)
    static let move = Action(id: 6, title: MailResourcesStrings.buttonMove, icon: MailResourcesAsset.emailActionSend21)
    static let postpone = Action(id: 7, title: MailResourcesStrings.buttonPostpone, icon: MailResourcesAsset.waitingMessage)
    static let spam = Action(id: 8, title: MailResourcesStrings.buttonSpam, icon: MailResourcesAsset.spam)
    static let block = Action(id: 9, title: MailResourcesStrings.buttonBlockSender, icon: MailResourcesAsset.blockUser)
    static let phishing = Action(id: 10, title: MailResourcesStrings.buttonPhishing, icon: MailResourcesAsset.fishing)
    static let print = Action(id: 11, title: MailResourcesStrings.buttonPrint, icon: MailResourcesAsset.printText)
    static let saveAsPDF = Action(id: 12, title: MailResourcesStrings.buttonSavePDF, icon: MailResourcesAsset.fileDownload)
    static let openIn = Action(id: 13, title: MailResourcesStrings.buttonOpenIn, icon: MailResourcesAsset.sendTo)
    static let createRule = Action(id: 14, title: MailResourcesStrings.buttonCreateRule, icon: MailResourcesAsset.ruleRegle)
    static let report = Action(id: 15, title: MailResourcesStrings.buttonReportDisplayProblem, icon: MailResourcesAsset.feedbacks)
    static let editMenu = Action(id: 16, title: MailResourcesStrings.buttonEditMenu, icon: MailResourcesAsset.editTools)

    static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.id == rhs.id
    }
}

enum ActionsTarget: Equatable {
    case threads([Thread])
    case thread(Thread)
    case message(Message)
}

@MainActor class ActionsViewModel: ObservableObject {
    private let mailboxManager: MailboxManager
    private var target: ActionsTarget

    @Published var quickActions: [Action] = []
    @Published var listActions: [Action] = []

    init(mailboxManager: MailboxManager, target: ActionsTarget) {
        self.mailboxManager = mailboxManager
        self.target = target
        setActions()
    }

    private func setActions() {
        // In the future, we might want to adjust the actions based on the target
        quickActions = [.delete, .reply, .archive, .forward]
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
            delete()
        case .reply:
            reply()
        case .archive:
            archive()
        case .forward:
            forward()
        case .markAsRead, .markAsUnread:
            toggleRead()
        case .move:
            move()
        case .postpone:
            postpone()
        case .spam:
            spam()
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

    // MARK: - Actions methods

    private func delete() {
        print("DELETE ACTION")
    }

    private func reply() {
        print("REPLY ACTION")
    }

    private func archive() {
        print("ARCHIVE")
    }

    private func forward() {
        print("FORWARD ACTION")
    }

    private func toggleRead() {
        Task {
            switch target {
            case .threads(let threads):
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for thread in threads {
                        group.addTask {
                            try await self.mailboxManager.toggleRead(thread: thread)
                        }
                    }
                    try await group.waitForAll()
                }
            case .thread(let thread):
                try await mailboxManager.toggleRead(thread: thread)
            case .message(let message):
                try await mailboxManager.markAsSeen(message: message, seen: !message.seen)
            }
        }
    }

    private func move() {
        print("MOVE ACTION")
    }

    private func postpone() {
        print("POSTPONE ACTION")
    }

    private func spam() {
        print("SPAM ACTION")
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
