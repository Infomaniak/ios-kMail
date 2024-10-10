/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

extension Action: CaseIterable {
    public static let rightClickActions: [Action] = [
        .activeMultiselect,
        .reply,
        .replyAll,
        .forward,
        .openMovePanel,
        .archive,
        .delete
    ]
    public static let quickActions: [Action] = [.reply, .replyAll, .forward, .delete]
    public static let swipeActions: [Action] = [
        .delete,
        .markAsRead,
        .openMovePanel,
        .star,
        .spam,
        .quickActionPanel,
        .archive,
        .noAction
    ]
    public static let allCases: [Action] = [
        .delete,
        .reply,
        .replyAll,
        .archive,
        .forward,
        .markAsRead,
        .markAsUnread,
        .openMovePanel,
        .star,
        .star,
        .unstar,
        .reportJunk,
        .spam,
        .nonSpam,
        .block,
        .phishing,
        .reportDisplayProblem,
        .editMenu,
        .moveToInbox,
        .writeEmailAction,
        .addContactsAction,
        .copyEmailAction,
        .noAction,
        .quickActionPanel
    ]

    public var refreshSearchResult: Bool {
        switch self {
        case .moved, .archive, .delete:
            return true
        default:
            return false
        }
    }

    private static func actionsForMessage(_ message: Message, origin: ActionOrigin,
                                          userIsStaff: Bool) -> (quickActions: [Action], listActions: [Action]) {
        @LazyInjectService var platformDetector: PlatformDetectable

        let archive = message.folder?.role != .archive
        let unread = !message.seen
        let star = message.flagged
        let spam = message.folder?.role == .spam
        let print = origin.type == .floatingPanel(source: .messageList)
        let tempListActions: [Action?] = [
            .openMovePanel,
            spam ? .nonSpam : .reportJunk,
            unread ? .markAsRead : .markAsUnread,
            archive ? .archive : .moveToInbox,
            star ? .unstar : .star,
            print ? .print : nil,
            .shareMailLink,
            platformDetector.isMac ? nil : .saveMailInkDrive,
            userIsStaff ? .reportDisplayProblem : nil
        ]

        return (Action.quickActions, tempListActions.compactMap { $0 })
    }

    private static func actionsForMessagesInDifferentThreads(_ messages: [Message], originFolder: Folder?)
        -> (quickActions: [Action], listActions: [Action]) {
        let unread = messages.allSatisfy(\.seen)
        let archive = originFolder?.role != .archive
        let quickActions: [Action] = [
            .openMovePanel,
            unread ? .markAsUnread : .markAsRead,
            archive ? .archive : .moveToInbox,
            .delete
        ]

        let spam = originFolder?.role == .spam
        let star = messages.allSatisfy(\.flagged)

        let listActions: [Action] = [
            spam ? .nonSpam : .reportJunk,
            star ? .unstar : .star,
            .saveThreadInkDrive
        ]

        return (quickActions, listActions)
    }

    private static func actionsForMessagesInSameThreads(_ messages: [Message], originFolder: Folder?)
        -> (quickActions: [Action], listActions: [Action]) {
        let archive = originFolder?.role != .archive
        let unread = messages.allSatisfy(\.seen)
        let showUnstar = messages.contains { $0.flagged }

        let spam = originFolder?.role == .spam
        let spamAction: Action? = spam ? .nonSpam : .reportJunk

        let tempListActions: [Action?] = [
            .openMovePanel,
            spamAction,
            unread ? .markAsUnread : .markAsRead,
            archive ? .archive : .moveToInbox,
            showUnstar ? .unstar : .star,
            .saveThreadInkDrive
        ]

        return (Action.quickActions, tempListActions.compactMap { $0 })
    }

    public static func actionsForMessages(_ messages: [Message],
                                          origin: ActionOrigin,
                                          userIsStaff: Bool) -> (quickActions: [Action], listActions: [Action]) {
        if messages.count == 1, let message = messages.first {
            return actionsForMessage(message, origin: origin, userIsStaff: userIsStaff)
        } else if messages.uniqueThreadsInFolder(origin.frozenFolder).count > 1 {
            return actionsForMessagesInDifferentThreads(messages, originFolder: origin.frozenFolder)
        } else {
            return actionsForMessagesInSameThreads(messages, originFolder: origin.frozenFolder)
        }
    }
}

extension Action: RawRepresentable {
    public var rawValue: String {
        return id
    }

    public init?(rawValue: String) {
        guard let action = Action.allCases.first(where: { $0.rawValue == rawValue }) else { return nil }
        id = action.id
        title = action.title
        shortTitle = action.shortTitle
        iconName = action.iconName
        tintColorName = action.tintColorName
        isDestructive = action.isDestructive
        matomoName = action.matomoName
    }
}

public extension Action {
    // MARK: Mail actions

    static let delete = Action(
        id: "delete",
        title: MailResourcesStrings.Localizable.actionDelete,
        iconResource: MailResourcesAsset.bin,
        tintColorResource: MailResourcesAsset.swipeDeleteColor,
        isDestructive: true,
        matomoName: "delete"
    )
    static let reply = Action(
        id: "reply",
        title: MailResourcesStrings.Localizable.actionReply,
        iconResource: MailResourcesAsset.emailActionReply,
        matomoName: "reply"
    )
    static let replyAll = Action(
        id: "replyAll",
        title: MailResourcesStrings.Localizable.actionReplyAll,
        iconResource: MailResourcesAsset.emailActionReplyToAll,
        matomoName: "replyAll"
    )
    static let archive = Action(
        id: "archive",
        title: MailResourcesStrings.Localizable.actionArchive,
        iconResource: MailResourcesAsset.archives,
        tintColorResource: MailResourcesAsset.swipeArchiveColor,
        isDestructive: true,
        matomoName: "archive"
    )
    static let forward = Action(
        id: "forward",
        title: MailResourcesStrings.Localizable.actionForward,
        iconResource: MailResourcesAsset.emailActionForward,
        matomoName: "forward"
    )
    static let markAsRead = Action(
        id: "markAsRead",
        title: MailResourcesStrings.Localizable.actionMarkAsRead,
        shortTitle: MailResourcesStrings.Localizable.actionShortMarkAsRead,
        iconResource: MailResourcesAsset.envelopeOpen,
        tintColorResource: MailResourcesAsset.swipeReadColor,
        matomoName: "markAsSeen"
    )
    static let markAsUnread = Action(
        id: "markAsUnread",
        title: MailResourcesStrings.Localizable.actionMarkAsUnread,
        shortTitle: MailResourcesStrings.Localizable.actionShortMarkAsUnread,
        iconResource: MailResourcesAsset.envelope,
        tintColorResource: MailResourcesAsset.swipeReadColor,
        matomoName: "markAsSeen"
    )
    static let openMovePanel = Action(
        id: "openMovePanel",
        title: MailResourcesStrings.Localizable.actionMove,
        iconResource: MailResourcesAsset.emailActionSend,
        tintColorResource: MailResourcesAsset.swipeMoveColor,
        matomoName: "move"
    )
    static let star = Action(
        id: "star",
        title: MailResourcesStrings.Localizable.actionStar,
        shortTitle: MailResourcesStrings.Localizable.actionShortStar,
        iconResource: MailResourcesAsset.star,
        tintColorResource: MailResourcesAsset.swipeFavoriteColor,
        matomoName: "favorite"
    )
    static let unstar = Action(
        id: "unstar",
        title: MailResourcesStrings.Localizable.actionUnstar,
        shortTitle: MailResourcesStrings.Localizable.actionShortStar,
        iconResource: MailResourcesAsset.unstar,
        tintColorResource: MailResourcesAsset.swipeFavoriteColor,
        matomoName: "favorite"
    )
    static let print = Action(
        id: "print",
        title: MailResourcesStrings.Localizable.actionPrint,
        iconResource: MailResourcesAsset.printText,
        matomoName: "print"
    )
    static let reportJunk = Action(
        id: "reportJunk",
        title: MailResourcesStrings.Localizable.actionReportJunk,
        iconResource: MailResourcesAsset.report,
        matomoName: "reportJunk"
    )
    static let spam = Action(
        id: "spam",
        title: MailResourcesStrings.Localizable.actionSpam,
        shortTitle: MailResourcesStrings.Localizable.actionShortSpam,
        iconResource: MailResourcesAsset.spam,
        tintColorResource: MailResourcesAsset.swipeSpamColor,
        isDestructive: true,
        matomoName: "spam"
    )
    static let nonSpam = Action(
        id: "nonSpam",
        title: MailResourcesStrings.Localizable.actionNonSpam,
        iconResource: MailResourcesAsset.spam,
        tintColorResource: MailResourcesAsset.swipeSpamColor,
        matomoName: "spam"
    )
    static let block = Action(
        id: "block",
        title: MailResourcesStrings.Localizable.actionBlockSender,
        iconResource: MailResourcesAsset.blockUser,
        matomoName: "blockUser"
    )
    static let blockList = Action(
        id: "blockList",
        title: MailResourcesStrings.Localizable.actionBlockSender,
        iconResource: MailResourcesAsset.blockUser,
        matomoName: "blockUser"
    )
    static let phishing = Action(
        id: "phishing",
        title: MailResourcesStrings.Localizable.actionPhishing,
        iconResource: MailResourcesAsset.phishing,
        matomoName: "signalPhishing"
    )
    static let reportDisplayProblem = Action(
        id: "reportDisplayProblem",
        title: MailResourcesStrings.Localizable.actionReportDisplayProblem,
        iconResource: MailResourcesAsset.feedbacks,
        matomoName: "report"
    )
    static let editMenu = Action(
        id: "editMenu",
        title: MailResourcesStrings.Localizable.actionEditMenu,
        iconResource: MailResourcesAsset.editTools,
        matomoName: "editMenu"
    )
    static let moveToInbox = Action(
        id: "moveToInbox",
        title: MailResourcesStrings.Localizable.actionMoveToInbox,
        shortTitle: MailResourcesStrings.Localizable.inboxFolder,
        iconResource: MailResourcesAsset.drawerDownload,
        tintColorResource: MailResourcesAsset.grayActionColor,
        isDestructive: true,
        matomoName: "moveToInbox"
    )
    static let writeEmailAction = Action(
        id: "writeEmailAction",
        title: MailResourcesStrings.Localizable.contactActionWriteEmail,
        iconResource: MailResourcesAsset.pencil,
        matomoName: "writeEmail"
    )
    static let addContactsAction = Action(
        id: "addContactsAction",
        title: MailResourcesStrings.Localizable.contactActionAddToContacts,
        iconResource: MailResourcesAsset.userAdd,
        matomoName: "addToContacts"
    )
    static let copyEmailAction = Action(
        id: "copyEmailAction",
        title: MailResourcesStrings.Localizable.contactActionCopyEmailAddress,
        iconResource: MailResourcesAsset.duplicate,
        matomoName: "copyEmailAddress"
    )
    static let noAction = Action(
        id: "none",
        title: MailResourcesStrings.Localizable.settingsSwipeActionNone,
        iconResource: MailResourcesAsset.duplicate,
        matomoName: "swipeNone"
    )
    static let quickActionPanel = Action(
        id: "swipeQuickAction",
        title: MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu,
        iconResource: MailResourcesAsset.navigationMenu,
        tintColorResource: MailResourcesAsset.swipeQuickActionColor,
        matomoName: "quickActions"
    )
    /// Used to return an Action in the movePanel completion
    static let moved = Action(
        id: "fakeActionMove",
        title: "",
        iconResource: MailResourcesAsset.emailActionSend,
        matomoName: ""
    )
    static let shareMailLink = Action(
        id: "shareMailLink",
        title: MailResourcesStrings.Localizable.shareEmail,
        iconResource: MailResourcesAsset.emailActionShare,
        matomoName: "shareLink"
    )
    static let saveMailInkDrive = Action(
        id: "saveMailInkDrive",
        title: MailResourcesStrings.Localizable.saveMailInkDrive,
        iconResource: MailResourcesAsset.kdriveLogo,
        matomoName: "saveInkDrive"
    )
    static let saveThreadInkDrive = Action(
        id: "saveThreadInkDrive",
        title: MailResourcesStrings.Localizable.saveMailInkDrive,
        iconResource: MailResourcesAsset.kdriveLogo,
        matomoName: "saveThreadInkDrive"
    )

    // MARK: Account Actions

    static let addAccount = Action(
        id: "addAccount",
        title: MailResourcesStrings.Localizable.buttonAddAccount,
        iconResource: MailResourcesAsset.plusThin,
        matomoName: "add"
    )
    static let logoutAccount = Action(
        id: "logoutAccount",
        title: MailResourcesStrings.Localizable.buttonAccountLogOut,
        iconResource: MailResourcesAsset.logout,
        matomoName: "logout"
    )
    static let deleteAccount = Action(
        id: "deleteAccount",
        title: MailResourcesStrings.Localizable.buttonAccountDelete,
        iconResource: MailResourcesAsset.bin,
        matomoName: "deleteAccount"
    )
    static let activeMultiselect = Action(
        id: "activeMultiselect",
        title: MailResourcesStrings.Localizable.buttonMultiselect,
        iconResource: MailResourcesAsset.checklist,
        matomoName: ""
    )
}
