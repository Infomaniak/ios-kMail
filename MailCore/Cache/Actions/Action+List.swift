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
        .quickActionPanel,
        .snooze,
        .modifySnooze,
        .cancelSnooze
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
            .modifySnooze,
            .star,
            .markAsRead,
            .markAsUnread
        ].contains(self)
    }

    public static func allAvailableSwipeActions() -> [Action] {
        @InjectService var featureFlagsManageable: FeatureFlagsManageable
        let isFeatureFlagEnabled = featureFlagsManageable.isEnabled(.mailSnooze)
        let isModeCorrect = UserDefaults.shared.threadMode == .conversation
        let hasAccessToSnoozeFeature = isFeatureFlagEnabled && isModeCorrect

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
                                          userEmail: String) -> Action.Lists {
        guard !messages.allSatisfy({ $0.isScheduledDraft == true }),
              !messages.allSatisfy({ $0.isDraft })
        else {
            return Action.Lists(
                quickActions: [],
                listActions: origin.type == .floatingPanel(source: .contextMenu) ? [.activeMultiSelect] : [],
                bottomBarActions: [.delete]
            )
        }
        return actionsForNormalMessages(messages, origin: origin, userIsStaff: userIsStaff, userEmail: userEmail)
    }

    private static func getArchiveAction(
        originType: ActionOrigin.ActionOriginType,
        originFolderRole: FolderRole?,
        messagesAreSnoozed: Bool
    ) -> Action? {
        guard originType != .floatingPanel(source: .messageList),
              originType != .floatingPanel(source: .messageDetails),
              originFolderRole != .spam,
              !messagesAreSnoozed
        else {
            return nil
        }
        return originFolderRole != .archive ? .archive : .moveToInbox
    }

    private static func getSpamAction(originFolderRole: FolderRole?, messagesRecipients: [Recipient],
                                      userEmail: String) -> Action? {
        guard !messagesRecipients.allSatisfy({ $0.isMeOrPlusMe(currentMailboxEmail: userEmail) }) else {
            return nil
        }
        return originFolderRole == .spam ? .nonSpam : .reportJunk
    }

    private static func getReportDisplayProblemAction(userIsStaff: Bool, messagesType: MessagesType) -> Action? {
        guard userIsStaff, messagesType.isSingle else {
            return nil
        }
        return .reportDisplayProblem
    }

    private static func getBottomBarActions(messagesType: MessagesType, unreadAction: Action?, archiveAction: Action?, starAction: Action?) -> [Action?] {
        switch messagesType {
        case .single, .multipleInSameThread:
            [.reply, .forward, archiveAction, .delete]
        case .multipleInDifferentThreads:
            [unreadAction, archiveAction, starAction, .delete]
        }
    }

    private static func actionsForNormalMessages(_ messages: [Message],
                                                 origin: ActionOrigin,
                                                 userIsStaff: Bool,
                                                 userEmail: String)
        -> Action.Lists {
        @LazyInjectService var platformDetector: PlatformDetectable

        let messagesType = MessagesType(messages, frozenFolder: origin.frozenFolder)

        let unreadAction: Action = messages.allSatisfy(\.seen) ? .markAsUnread : .markAsRead
        let archiveAction = getArchiveAction(
            originType: origin.type,
            originFolderRole: origin.frozenFolder?.role,
            messagesAreSnoozed: messages.allSatisfy(\.isSnoozed)
        )
        let openMovePanelAction: Action? = messages.allSatisfy(\.isMovable) ? .openMovePanel : nil
        let spamAction = getSpamAction(
            originFolderRole: origin.frozenFolder?.role,
            messagesRecipients: messages.flatMap(\.from),
            userEmail: userEmail
        )
        let starAction: Action = messages.contains { $0.flagged } ? .unstar : .star
        let reportDisplayProblemAction = getReportDisplayProblemAction(userIsStaff: userIsStaff, messagesType: messagesType)

        let quickActions: [Action] = !origin.type.isListed ? [.reply, .replyAll, .forward, .delete] : []

        var listActions: [Action?] = [origin.type == .floatingPanel(source: .contextMenu) ? .activeMultiSelect : nil] +
            (origin
                .type != .floatingPanel(source: .messageDetails) ? snoozedActions(messages, folder: origin.frozenFolder) : []) +
            [openMovePanelAction, spamAction]

        if origin.type != .floatingPanel(source: .threadList) {
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

        var bottomBarActions = getBottomBarActions(messagesType: messagesType, unreadAction: unreadAction, archiveAction: archiveAction, starAction: starAction)

        return Action.Lists(
            quickActions: quickActions,
            listActions: listActions.compactMap { $0 },
            bottomBarActions: bottomBarActions.compactMap { $0 }
        )
    }

    private enum MessagesType {
        case single
        case multipleInSameThread
        case multipleInDifferentThreads

        init(_ messages: [Message], frozenFolder: Folder?) {
            if messages.count == 1 {
                self = .single
            } else if messages.uniqueThreadsInFolder(frozenFolder).count == 1 {
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
        matomoName = action.matomoName
    }
}

public extension Action {
    // MARK: Thread actions

    static let snooze = Action(
        id: "snooze",
        title: MailResourcesStrings.Localizable.actionSnooze,
        iconResource: MailResourcesAsset.alarmClock,
        tintColorResource: MailResourcesAsset.swipeSnoozeColor,
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

    static let snoozed = Action(
        id: "fakeSnooze",
        title: "",
        iconResource: MailResourcesAsset.alarmClock,
        matomoName: ""
    )
    static let modifiedSnoozed = Action(
        id: "fakeModifiedSnooze",
        title: "",
        iconResource: MailResourcesAsset.alarmClock,
        matomoName: ""
    )

    // MARK: Mail actions

    static let delete = Action(
        id: "delete",
        title: MailResourcesStrings.Localizable.actionDelete,
        iconResource: MailResourcesAsset.bin,
        tintColorResource: MailResourcesAsset.swipeDeleteColor,
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
