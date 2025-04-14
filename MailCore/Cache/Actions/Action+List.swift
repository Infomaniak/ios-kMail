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

    public var shouldDisableMultipleSelection: Bool {
        return ![
            .openMovePanel,
            .saveThreadInkDrive,
            .shareMailLink,
            .reportJunk,
            .phishing,
            .block,
            .blockList,
            .snooze,
            .modifySnooze
        ].contains(self)
    }

    private static func snoozedActions(_ messages: [Message], folder: Folder?) -> [Action] {
        guard folder?.canAccessSnoozeActions == true else { return [] }

        let messagesFromFolder = messages.filter { $0.folder?.remoteId == folder?.remoteId }
        guard !messagesFromFolder.isEmpty else { return [] }

        if messagesFromFolder.allSatisfy(\.isSnoozed) {
            return [.modifySnooze, .cancelSnooze]
        } else {
            return [.snooze]
        }
    }

    public static func actionsForMessages(_ messages: [Message],
                                          origin: ActionOrigin,
                                          userIsStaff: Bool,
                                          userEmail: String)
        -> Action.Lists {
        @LazyInjectService var platformDetector: PlatformDetectable

        let messagesType = MessagesType(messages, frozenFolder: origin.frozenFolder)

        let unreadAction: Action = messages.allSatisfy(\.seen) ? .markAsUnread : .markAsRead
        var archiveAction: Action? {
            guard origin.type != .floatingPanel(source: .messageList),
                  origin.type != .floatingPanel(source: .messageDetails) else { return nil }
            return origin.frozenFolder?.role != .archive ? .archive : .moveToInbox
        }
        var spamAction: Action? {
            let selfThread = messages.flatMap(\.from).allSatisfy { $0.isMeOrPlusMe(currentMailboxEmail: userEmail) }
            guard !selfThread else { return nil }
            return origin.frozenFolder?.role == .spam ? .nonSpam : .reportJunk
        }
        var starAction: Action {
            messages.contains { $0.flagged } ? .unstar : .star
        }
        var reportDisplayProblemAction: Action? {
            guard userIsStaff, messagesType.isSingle else { return nil }
            return .reportDisplayProblem
        }

        var quickActions: [Action] {
            guard messagesType.isSingle, origin.type == .floatingPanel(source: .messageDetails) else { return [] }

            return [.reply, .replyAll, .forward, .delete]
        }

        var listActions: [Action?] = [
            origin.type == .contextMenu ? .activeMultiSelect : nil,
            .openMovePanel,
            spamAction
        ]

        if (messagesType == .single && origin.type != .floatingPanel(source: .threadList))
            || origin.type == .floatingPanel(source: .messageList) {
            listActions += [
                unreadAction,
                starAction,
                archiveAction,
                messagesType.isSingle ? .print : nil,
                messagesType.isSingle ? .shareMailLink : nil,
                platformDetector.isMac ? nil : .saveThreadInkDrive,
                reportDisplayProblemAction
            ]
        }

        listActions = snoozedActions(messages, folder: origin.frozenFolder) + listActions

        var bottomBarActions: [Action] = []
        if origin.type != .contextMenu {
            switch messagesType {
            case .single, .multipleInSameThread:
                bottomBarActions = [.reply, .forward, .archive, .delete]
            case .multipleInDifferentThreads:
                bottomBarActions = [unreadAction, .archive, starAction, .delete]
            }
        }

        return Action.Lists(
            quickActions: quickActions,
            listActions: listActions.compactMap { $0 },
            bottomBarActions: bottomBarActions
        )
    }

    private enum MessagesType {
        case single
        case multipleInSameThread
        case multipleInDifferentThreads

        init(_ messages: [Message], frozenFolder: Folder?) {
            if messages.count == 1 {
                self = .single
            } else if messages.uniqueThreadsInFolder(frozenFolder).count > 1 {
                self = .multipleInSameThread
            } else {
                self = .multipleInDifferentThreads
            }
        }

        var isSingle: Bool { return self == .single }
    }

    public struct Lists {
        public let quickActions: [Action]
        public let listActions: [Action]
        public let bottomBarActions: [Action]
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
    // MARK: Thread actions

    static let snooze = Action(
        id: "snooze",
        title: MailResourcesStrings.Localizable.actionSnooze,
        iconResource: MailResourcesAsset.alarmClock,
        matomoName: "snooze"
    )
    static let modifySnooze = Action(
        id: "modifySnooze",
        title: MailResourcesStrings.Localizable.actionModifySnooze,
        iconResource: MailResourcesAsset.alarmClock,
        matomoName: "modifySnooze"
    )
    static let cancelSnooze = Action(
        id: "cancelSnooze",
        title: MailResourcesStrings.Localizable.actionCancelSnooze,
        iconResource: MailResourcesAsset.circleCross,
        matomoName: "cancelSnooze"
    )

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
    static let activeMultiSelect = Action(
        id: "activeMultiSelect",
        title: MailResourcesStrings.Localizable.buttonMultiselect,
        iconResource: MailResourcesAsset.checklist,
        matomoName: ""
    )
}
