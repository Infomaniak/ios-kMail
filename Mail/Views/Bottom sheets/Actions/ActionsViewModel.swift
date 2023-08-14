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
import SwiftUI

struct Action: Identifiable, Equatable {
    let id: Int
    let title: String
    let shortTitle: String?
    let icon: Image
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
        shortTitle: MailResourcesStrings.Localizable.actionShortStar,
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
        shortTitle: MailResourcesStrings.Localizable.actionShortSpam,
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
        icon: MailResourcesAsset.drawer,
        matomoName: "moveToInbox"
    )
    static let writeEmailAction = Action(
        id: 18,
        title: MailResourcesStrings.Localizable.contactActionWriteEmail,
        icon: MailResourcesAsset.pencil,
        matomoName: "writeEmail"
    )
    static let addContactsAction = Action(
        id: 19,
        title: MailResourcesStrings.Localizable.contactActionAddToContacts,
        icon: MailResourcesAsset.userAdd,
        matomoName: "addToContacts"
    )
    static let copyEmailAction = Action(
        id: 20,
        title: MailResourcesStrings.Localizable.contactActionCopyEmailAddress,
        icon: MailResourcesAsset.duplicate,
        matomoName: "copyEmailAddress"
    )

    static let quickActions: [Action] = [.reply, .replyAll, .forward, .delete]

    init(id: Int, title: String, shortTitle: String? = nil, icon: MailResourcesImages, matomoName: String?) {
        self.id = id
        self.title = title
        self.shortTitle = shortTitle
        self.icon = icon.swiftUIImage
        self.matomoName = matomoName
    }

    static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.id == rhs.id
    }
}

enum ActionsTarget: Equatable, Identifiable {
    var id: String {
        switch self {
        case .threads(let threads, _):
            return threads.map(\.id).joined()
        case .message(let message):
            return message.uid
        }
    }

    case threads([Thread], Bool)
    case message(Message)

    var isInvalidated: Bool {
        switch self {
        case .threads(let threads, _):
            return threads.contains(where: \.isInvalidated)
        case .message(let message):
            return message.isInvalidated
        }
    }

    func freeze() -> Self {
        switch self {
        case .threads(let threads, let isMultiSelectionEnabled):
            return .threads(threads.map { $0.freezeIfNeeded() }, isMultiSelectionEnabled)
        case .message(let message):
            return .message(message.freezeIfNeeded())
        }
    }
}

@MainActor class ActionsViewModel: ObservableObject {
    private let mailboxManager: MailboxManager
    private let target: ActionsTarget
    private let moveAction: Binding<MoveAction?>?
    private let messageReply: Binding<MessageReply?>?
    private let reportJunkActionsTarget: Binding<ActionsTarget?>?
    private let reportedForPhishingMessage: Binding<Message?>?
    private let reportedForDisplayProblemMessage: Binding<Message?>?
    private let completionHandler: (() -> Void)?

    private let matomoCategory: MatomoUtils.EventCategory?

    @Published var quickActions: [Action] = []
    @Published var listActions: [Action] = []

    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    init(mailboxManager: MailboxManager,
         target: ActionsTarget,
         moveAction: Binding<MoveAction?>? = nil,
         messageReply: Binding<MessageReply?>? = nil,
         reportJunkActionsTarget: Binding<ActionsTarget?>? = nil,
         reportedForPhishingMessage: Binding<Message?>? = nil,
         reportedForDisplayProblemMessage: Binding<Message?>? = nil,
         matomoCategory: MatomoUtils.EventCategory? = nil,
         completionHandler: (() -> Void)? = nil) {
        self.mailboxManager = mailboxManager
        switch target {
        case .threads(let threads, _):
            if threads.count == 1, let thread = threads.first, thread.messages.count == 1, let message = thread.messages.first {
                self.target = ActionsTarget.message(message).freeze()
            } else {
                self.target = target.freeze()
            }
        case .message:
            self.target = target.freeze()
        }
        self.moveAction = moveAction
        self.messageReply = messageReply
        self.reportJunkActionsTarget = reportJunkActionsTarget
        self.reportedForPhishingMessage = reportedForPhishingMessage
        self.reportedForDisplayProblemMessage = reportedForDisplayProblemMessage
        self.completionHandler = completionHandler
        self.matomoCategory = matomoCategory
        setActions()
    }

    private func setActions() {
        switch target {
        case .threads(let threads, _):
            if threads.count > 1 {
                let unread = threads.allSatisfy(\.hasUnseenMessages)
                quickActions = [.move, unread ? .markAsRead : .markAsUnread, .archive, .delete]

                let spam = threads.allSatisfy { $0.folder?.role == .spam }
                let star = threads.allSatisfy(\.flagged)
                listActions = [
                    spam ? .nonSpam : .spam,
                    star ? .unstar : .star
                ]
            } else if let thread = threads.first {
                quickActions = Action.quickActions

                let archive = thread.folder?.role != .archive
                let unread = thread.hasUnseenMessages
                let star = thread.flagged

                let spam = thread.folder?.role == .spam
                let spamAction: Action? = spam ? .nonSpam : .spam

                let tempListActions: [Action?] = [
                    .move,
                    spamAction,
                    unread ? .markAsRead : .markAsUnread,
                    archive ? .archive : .moveToInbox,
                    star ? .unstar : .star
                ]

                listActions = tempListActions.compactMap { $0 }
            }
        case .message(let message):
            quickActions = Action.quickActions

            let archive = message.folder?.role != .archive
            let unread = !message.seen
            let star = message.flagged
            let isStaff = mailboxManager.account.user?.isStaff ?? false
            let tempListActions: [Action?] = [
                .move,
                .reportJunk,
                unread ? .markAsRead : .markAsUnread,
                archive ? .archive : .moveToInbox,
                star ? .unstar : .star,
                isStaff ? .report : nil
            ]

            listActions = tempListActions.compactMap { $0 }
        }
    }

    func didTap(action: Action) async throws {
        if let matomoCategory, let matomoName = action.matomoName {
            if case .threads(let threads, let isMultipleSelectionEnabled) = target, isMultipleSelectionEnabled {
                matomo.trackBulkEvent(
                    eventWithCategory: matomoCategory,
                    name: matomoName.capitalized,
                    numberOfItems: threads.count
                )
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
            try await ActionUtils(actionsTarget: target, mailboxManager: mailboxManager).move(to: .archive)
        case .forward:
            try await reply(mode: .forward)
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
            try await ActionUtils(actionsTarget: target, mailboxManager: mailboxManager).move(to: .spam)
        case .nonSpam:
            try await ActionUtils(actionsTarget: target, mailboxManager: mailboxManager).move(to: .inbox)
        case .block:
            try await block()
        case .phishing:
            try await phishing()
        case .print:
            printAction()
        case .report:
            reportDisplayProblem()
        case .editMenu:
            editMenu()
        case .moveToInbox:
            try await ActionUtils(actionsTarget: target, mailboxManager: mailboxManager).move(to: .inbox)
        default:
            print("Warning: Unhandled action!")
        }
        completionHandler?()
    }

    // MARK: - Actions methods

    private func delete() async throws {
        switch target {
        case .threads(let threads, _):
            try await mailboxManager.moveOrDelete(threads: threads)
        case .message(let message):
            try await mailboxManager.moveOrDelete(messages: [message])
        }
    }

    private func reply(mode: ReplyMode) async throws {
        var displayedMessageReply: MessageReply?
        switch target {
        case .threads(let threads, _):
            // We don't handle this action in multiple selection
            guard threads.count == 1, let thread = threads.first,
                  let message = thread.lastMessageToExecuteAction(currentMailboxEmail: mailboxManager.mailbox.email)
            else { break }
            displayedMessageReply = MessageReply(message: message, replyMode: mode)
        case .message(let message):
            displayedMessageReply = MessageReply(message: message, replyMode: mode)
        }
        // FIXME: There seems to be a bug where SwiftUI looses the "context" and attempts to present
        // the view controller before waiting for the dismiss of the first one if we use a closure
        // (this "fix" is temporary)
        DispatchQueue.main.async { [weak self] in
            self?.messageReply?.wrappedValue = displayedMessageReply
        }
    }

    private func toggleRead() async throws {
        switch target {
        case .threads(let threads, _):
            try await mailboxManager.toggleRead(threads: threads)
        case .message(let message):
            try await mailboxManager.markAsSeen(message: message, seen: !message.seen)
        }
    }

    private func move() {
        let folderId: String?
        switch target {
        case .threads(let threads, _):
            folderId = threads.first?.folder?.id
        case .message(let message):
            folderId = message.folderId
        }

        DispatchQueue.main.async { [weak self, target] in
            self?.moveAction?.wrappedValue = MoveAction(fromFolderId: folderId, target: target)
        }
    }

    private func postpone() {
        // TODO: POSTPONE ACTION
        showWorkInProgressSnackBar()
    }

    private func star() async throws {
        await tryOrDisplayError {
            switch target {
            case .threads(let threads, _):
                try await mailboxManager.toggleStar(threads: threads)
            case .message(let message):
                try await mailboxManager.toggleStar(messages: [message])
            }
        }
    }

    private func displayReportJunk() {
        reportJunkActionsTarget?.wrappedValue = target
    }

    private func block() async throws {
        // This action is only available on a single message
        guard case .message(let message) = target else { return }
        _ = try await mailboxManager.apiFetcher.blockSender(message: message)
        snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarSenderBlacklisted(1))
    }

    private func phishing() async throws {
        // This action is only available on a single message
        guard case .message(let message) = target else { return }
        DispatchQueue.main.async { [weak self] in
            self?.reportedForPhishingMessage?.wrappedValue = message
        }
    }

    private func printAction() {
        // TODO: PRINT ACTION
        showWorkInProgressSnackBar()
    }

    private func reportDisplayProblem() {
        // This action is only available on a single message
        guard case .message(let message) = target else { return }
        DispatchQueue.main.async { [weak self] in
            self?.reportedForDisplayProblemMessage?.wrappedValue = message
        }
    }

    private func editMenu() {
        // TODO: EDIT MENU ACTION
        showWorkInProgressSnackBar()
    }
}
