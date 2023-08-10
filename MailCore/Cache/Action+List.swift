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
import MailResources

public extension Action {
    static let quickActions: [Action] = [.reply, .replyAll, .forward, .delete]
}

public extension Action {
    static let delete = Action(
        title: MailResourcesStrings.Localizable.actionDelete,
        icon: MailResourcesAsset.bin,
        matomoName: "delete"
    )
    static let reply = Action(
        title: MailResourcesStrings.Localizable.actionReply,
        icon: MailResourcesAsset.emailActionReply,
        matomoName: "reply"
    )
    static let replyAll = Action(
        title: MailResourcesStrings.Localizable.actionReplyAll,
        icon: MailResourcesAsset.emailActionReplyToAll,
        matomoName: "replyAll"
    )
    static let archive = Action(
        title: MailResourcesStrings.Localizable.actionArchive,
        icon: MailResourcesAsset.archives,
        matomoName: "archive"
    )
    static let forward = Action(
        title: MailResourcesStrings.Localizable.actionForward,
        icon: MailResourcesAsset.emailActionTransfer,
        matomoName: "forward"
    )
    static let markAsRead = Action(
        title: MailResourcesStrings.Localizable.actionMarkAsRead,
        shortTitle: MailResourcesStrings.Localizable.actionShortMarkAsRead,
        icon: MailResourcesAsset.envelopeOpen,
        matomoName: "markAsSeen"
    )
    static let markAsUnread = Action(
        title: MailResourcesStrings.Localizable.actionMarkAsUnread,
        shortTitle: MailResourcesStrings.Localizable.actionShortMarkAsUnread,
        icon: MailResourcesAsset.envelope,
        matomoName: "markAsSeen"
    )
    static let openMovePanel = Action(
        title: MailResourcesStrings.Localizable.actionMove,
        icon: MailResourcesAsset.emailActionSend,
        matomoName: "move"
    )
    static let postpone = Action(
        title: MailResourcesStrings.Localizable.actionPostpone,
        icon: MailResourcesAsset.waitingMessage,
        matomoName: "postpone"
    )
    static let star = Action(
        title: MailResourcesStrings.Localizable.actionStar,
        shortTitle: MailResourcesStrings.Localizable.actionShortStar,
        icon: MailResourcesAsset.star,
        matomoName: "favorite"
    )
    static let unstar = Action(
        title: MailResourcesStrings.Localizable.actionUnstar,
        shortTitle: MailResourcesStrings.Localizable.actionShortStar,
        icon: MailResourcesAsset.unstar,
        matomoName: "favorite"
    )
    static let reportJunk = Action(
        title: MailResourcesStrings.Localizable.actionReportJunk,
        icon: MailResourcesAsset.report,
        matomoName: nil
    )
    static let spam = Action(
        title: MailResourcesStrings.Localizable.actionSpam,
        shortTitle: MailResourcesStrings.Localizable.actionShortSpam,
        icon: MailResourcesAsset.spam,
        matomoName: "spam"
    )
    static let nonSpam = Action(
        title: MailResourcesStrings.Localizable.actionNonSpam,
        icon: MailResourcesAsset.spam,
        matomoName: "spam"
    )
    static let block = Action(
        title: MailResourcesStrings.Localizable.actionBlockSender,
        icon: MailResourcesAsset.blockUser,
        matomoName: "blockUser"
    )
    static let phishing = Action(
        title: MailResourcesStrings.Localizable.actionPhishing,
        icon: MailResourcesAsset.phishing,
        matomoName: "signalPhishing"
    )
    static let print = Action(
        title: MailResourcesStrings.Localizable.actionPrint,
        icon: MailResourcesAsset.printText,
        matomoName: "print"
    )
    static let report = Action(
        title: MailResourcesStrings.Localizable.actionReportDisplayProblem,
        icon: MailResourcesAsset.feedbacks,
        matomoName: nil
    )
    static let editMenu = Action(
        title: MailResourcesStrings.Localizable.actionEditMenu,
        icon: MailResourcesAsset.editTools,
        matomoName: "editMenu"
    )
    static let moveToInbox = Action(
        title: MailResourcesStrings.Localizable.actionMoveToInbox,
        icon: MailResourcesAsset.drawer,
        matomoName: "moveToInbox"
    )
    static let writeEmailAction = Action(
        title: MailResourcesStrings.Localizable.contactActionWriteEmail,
        icon: MailResourcesAsset.pencil,
        matomoName: "writeEmail"
    )
    static let addContactsAction = Action(
        title: MailResourcesStrings.Localizable.contactActionAddToContacts,
        icon: MailResourcesAsset.userAdd,
        matomoName: "addToContacts"
    )
    static let copyEmailAction = Action(
        title: MailResourcesStrings.Localizable.contactActionCopyEmailAddress,
        icon: MailResourcesAsset.duplicate,
        matomoName: "copyEmailAddress"
    )
}
