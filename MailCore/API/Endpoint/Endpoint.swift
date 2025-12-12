/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

// MARK: - Type definition

public extension ApiEnvironment {
    var mailHost: String {
        return "mail.\(host)"
    }

    var calendarHost: String {
        return "calendar.\(host)"
    }
}

extension Endpoint {
    func alsoMoveReactions(_ moveReactions: Bool) -> Endpoint {
        guard moveReactions else {
            return self
        }

        return appending(path: "", queryItems: [URLQueryItem(name: "move_reactions", value: "1")])
    }
}

// MARK: - Endpoints

public extension Endpoint {
    static func resource(_ resource: String, queryItems: [URLQueryItem]? = nil) -> Endpoint {
        let components = URLComponents(string: resource)
        var mergedQueryItems = components?.queryItems
        if mergedQueryItems == nil {
            mergedQueryItems = queryItems
        } else if let queryItems {
            mergedQueryItems?.append(contentsOf: queryItems)
        }

        return .mailHost.appending(path: components?.path ?? resource, queryItems: mergedQueryItems)
    }

    private static var baseManager: Endpoint {
        return Endpoint(path: "/1/mail_hostings")
    }

    private static func baseManagerMailbox(hostingId: Int, mailboxName: String) -> Endpoint {
        return .baseManager.appending(path: "/\(hostingId)/mailboxes/\(mailboxName)")
    }

    private static var mailHost: Endpoint {
        return Endpoint(hostKeypath: \.mailHost, path: "")
    }

    private static var base: Endpoint {
        return .mailHost.appending(path: "/api")
    }

    static var ping: Endpoint {
        return .base.appending(path: "/ping")
    }

    static var mailboxes: Endpoint {
        return .base.appending(
            path: "/mailbox",
            queryItems: [URLQueryItem(name: "with", value: "unseen,aliases")]
        )
    }

    internal static func mailbox(uuid: String) -> Endpoint {
        return .base.appending(path: "/mail/\(uuid)")
    }

    static func mailHosting(mailbox: Mailbox) -> Endpoint {
        return .base.appending(path: "/securedProxy/1/mail_hostings/\(mailbox.hostingId)/mailboxes/\(mailbox.mailbox)")
    }

    static func sendersRestrictions(mailbox: Mailbox) -> Endpoint {
        return .mailHosting(mailbox: mailbox).appending(
            path: "",
            queryItems: [URLQueryItem(name: "with", value: "authorized_senders,blocked_senders")]
        )
    }

    static func permissions(mailbox: Mailbox) -> Endpoint {
        return .base.appending(path: "/mailbox/permissions",
                               queryItems: [URLQueryItem(name: "user_mailbox_id", value: "\(mailbox.linkId)"),
                                            URLQueryItem(name: "product_id", value: "\(mailbox.hostingId)")])
    }

    static func featureFlag(_ mailboxUUID: String) -> Endpoint {
        return .base.appending(path: "/feature-flag/check", queryItems: [URLQueryItem(name: "mailbox_uuid", value: mailboxUUID)])
    }

    static var addressBooks: Endpoint {
        return .base.appending(
            path: "/pim/addressbook",
            queryItems: [URLQueryItem(name: "with", value: "categories,account_name")]
        )
    }

    static var contacts: Endpoint {
        return .base.appending(
            path: "/pim/contact/all",
            queryItems: [URLQueryItem(name: "with", value: "emails,details,others,contacted_times"),
                         URLQueryItem(name: "filters", value: "has_email")]
        )
    }

    static var addContact: Endpoint {
        return .base.appending(path: "/pim/contact")
    }

    static func ai(mailbox: Mailbox? = nil) -> Endpoint {
        var queryItems = [URLQueryItem]()
        if let mailbox {
            queryItems.append(URLQueryItem(name: "mailbox_uuid", value: mailbox.uuid))
        }
        return .base.appending(path: "/ai", queryItems: queryItems)
    }

    static func aiShortcut(contextId: String? = nil, shortcut: String, mailbox: Mailbox) -> Endpoint {
        var mobileAIEndpoint = Endpoint.ai().appending(path: "/mobile")
        if let contextId {
            mobileAIEndpoint = mobileAIEndpoint.appending(path: "/\(contextId)")
        }
        return mobileAIEndpoint.appending(
            path: "/\(shortcut)",
            queryItems: [URLQueryItem(name: "mailbox_uuid", value: mailbox.uuid)]
        )
    }

    static func backups(hostingId: Int, mailboxName: String) -> Endpoint {
        return .baseManagerMailbox(hostingId: hostingId, mailboxName: mailboxName).appending(path: "/backups")
    }

    static func signatures(hostingId: Int, mailboxName: String) -> Endpoint {
        return .baseManagerMailbox(hostingId: hostingId, mailboxName: mailboxName).appending(path: "/signatures")
    }

    static func updateSignature(hostingId: Int, mailboxName: String) -> Endpoint {
        return .signatures(hostingId: hostingId, mailboxName: mailboxName).appending(path: "/set_defaults")
    }

    static func folders(uuid: String) -> Endpoint {
        return .mailbox(uuid: uuid).appending(path: "/folder", queryItems: [URLQueryItem(name: "with", value: "ik-static")])
    }

    static func folder(uuid: String, folderUUID: String) -> Endpoint {
        return .folders(uuid: uuid).appending(path: "/\(folderUUID)")
    }

    static func modifyFolder(mailboxUuid: String, folderId: String) -> Endpoint {
        return .folders(uuid: mailboxUuid).appending(path: "/\(folderId)/rename")
    }

    static func flushFolder(mailboxUuid: String, folderId: String) -> Endpoint {
        return .folders(uuid: mailboxUuid).appending(path: "/\(folderId)/flush")
    }

    // MARK: - New Routes

    static func messages(mailboxUuid: String, folderId: String) -> Endpoint {
        return .base.appending(path: "/mail/\(mailboxUuid)/folder/\(folderId)/mobile")
    }

    static func messagesUids(mailboxUuid: String, folderId: String) -> Endpoint {
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "messages", value: Constants.numberOfOldUidsToFetch.toString()))
        queryItems.append(URLQueryItem(name: "direction", value: "desc"))

        return messages(mailboxUuid: mailboxUuid, folderId: folderId).appending(
            path: "/date-ordered-messages-uids",
            queryItems: queryItems
        )
    }

    static func messagesByUids(mailboxUuid: String, folderId: String, messagesUids: [String]) -> Endpoint {
        return .messages(mailboxUuid: mailboxUuid, folderId: folderId).appending(path: "/messages", queryItems: [
            URLQueryItem(name: "uids", value: messagesUids.joined(separator: ","))
        ])
    }

    static func messagesDelta(mailboxUuid: String, folderId: String, signature: String) -> Endpoint {
        return .messages(mailboxUuid: mailboxUuid, folderId: folderId).appending(path: "/activities", queryItems: [
            URLQueryItem(name: "signature", value: signature)
        ])
    }

    static func threads(uuid: String, folderId: String, offset: Int = 0, filter: String?,
                        searchFilters: [URLQueryItem] = [], isDraftFolder: Bool = false) -> Endpoint {
        var queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "thread", value: isDraftFolder ? "off" : "on"),
            URLQueryItem(name: "filters", value: filter),
            URLQueryItem(name: "with", value: "emoji_reactions_per_message")
        ]
        queryItems.append(contentsOf: searchFilters)
        return .folders(uuid: uuid).appending(path: "/\(folderId)/message", queryItems: queryItems)
    }

    static func quotas(mailbox: String, productId: Int) -> Endpoint {
        return .mailboxes.appending(path: "/quotas", queryItems: [
            URLQueryItem(name: "mailbox", value: mailbox),
            URLQueryItem(name: "product_id", value: "\(productId)")
        ])
    }

    static func externalMailFlag(hostingId: Int, mailboxName: String) -> Endpoint {
        return .baseManagerMailbox(hostingId: hostingId, mailboxName: mailboxName).appending(path: "/external_mail_flag")
    }

    static func draft(uuid: String) -> Endpoint {
        return .mailbox(uuid: uuid).appending(path: "/draft")
    }

    static func draft(uuid: String, draftUuid: String) -> Endpoint {
        return .draft(uuid: uuid).appending(path: "/\(draftUuid)")
    }

    static func draftSchedule(draftAction: String) -> Endpoint {
        return .resource(draftAction)
    }

    static func mailHosted(for recipients: [String]) -> Endpoint {
        var queryItems = [URLQueryItem]()
        for recipient in recipients {
            queryItems.append(URLQueryItem(name: "mailboxes[]", value: recipient))
        }
        return base.appending(
            path: "/securedProxy/1/mail_hostings/mailboxes/exist",
            queryItems: queryItems
        )
    }

    static func messageSeen(uuid: String) -> Endpoint {
        return .mailbox(uuid: uuid).appending(path: "/message/seen")
    }

    static func messageUnseen(uuid: String) -> Endpoint {
        return .mailbox(uuid: uuid).appending(path: "/message/unseen")
    }

    static func moveMessages(uuid: String, alsoMoveReactions: Bool) -> Endpoint {
        return .mailbox(uuid: uuid).appending(path: "/message/move").alsoMoveReactions(alsoMoveReactions)
    }

    static func deleteMessages(uuid: String, alsoMoveReactions: Bool) -> Endpoint {
        return .mailbox(uuid: uuid).appending(path: "/message/delete").alsoMoveReactions(alsoMoveReactions)
    }

    static func star(uuid: String) -> Endpoint {
        return .mailbox(uuid: uuid).appending(path: "/message/star")
    }

    static func unstar(uuid: String) -> Endpoint {
        return .mailbox(uuid: uuid).appending(path: "/message/unstar")
    }

    static func downloadAttachments(messageResource: String) -> Endpoint {
        return .resource(messageResource).appending(path: "/attachmentsArchive")
    }

    static func blockSender(messageResource: String) -> Endpoint {
        return .resource(messageResource).appending(path: "/blacklist")
    }

    static func report(messageResource: String) -> Endpoint {
        return .resource(messageResource).appending(path: "/report")
    }

    static func spam(uuid: String) -> Endpoint {
        return .mailbox(uuid: uuid).appending(path: "/message/spam")
    }

    static func createAttachment(uuid: String) -> Endpoint {
        return .draft(uuid: uuid).appending(path: "/attachment")
    }

    static func attachmentToForward(uuid: String) -> Endpoint {
        return .draft(uuid: uuid).appending(path: "/attachmentsToForward")
    }

    static func replyToCalendarEvent(resource: String) -> Endpoint {
        return .resource(resource).appending(path: "/reply")
    }

    static func replyToCalendarEventAndUpdateCalendar(id: Int) -> Endpoint {
        return .base.appending(path: "/pim/event/\(id)/reply")
    }

    static func importICSEventToCalendar(resource: String) -> Endpoint {
        return .resource(resource).appending(path: "/import-ics")
    }

    static func bimiSvgUrl(bimi: Bimi) -> Endpoint {
        return .mailHost.appending(path: "\(bimi.svgContent)")
    }

    static func swissTransfer(stUuid: String) -> Endpoint {
        return .base.appending(path: "/swisstransfer/containers/\(stUuid)")
    }

    static func downloadSwissTransferAttachment(stUuid: String, fileUuid: String) -> Endpoint {
        return .swissTransfer(stUuid: stUuid).appending(path: "/files/\(fileUuid)")
    }

    static func downloadAllSwissTransferAttachments(stUuid: String) -> Endpoint {
        return .swissTransfer(stUuid: stUuid).appending(path: "/files/download")
    }

    static func share(messageResource: String) -> Endpoint {
        return .resource(messageResource).appending(path: "/share")
    }

    static var lastSyncDate: Endpoint {
        return Endpoint(
            hostKeypath: \.calendarHost,
            path: "/api/sync-connection",
            queryItems: [URLQueryItem(name: "os", value: "ios")]
        )
    }

    static func unsubscribe(resource: String) -> Endpoint {
        return .resource(resource).appending(path: "/unsubscribeFromList")
    }

    static func acknowledge(resource: String) -> Endpoint {
        return .resource(resource).appending(path: "/acknowledge")
    }
}
