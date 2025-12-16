/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakLogin
import MailCore
import RealmSwift
import SwiftUI

public enum PreviewHelper {
    class MockSelectedThreadOwner: SelectedThreadOwnable {
        var selectedThread: MailCore.Thread?
    }

    public static let mockSelectedThreadOwner: SelectedThreadOwnable = MockSelectedThreadOwner()

    private class PreviewHelperRefreshTokenDelegate: RefreshTokenDelegate {
        func didUpdateToken(newToken: ApiToken, oldToken: ApiToken) {
            // No implementation
        }

        func didFailRefreshToken(_ token: ApiToken) {
            // No implementation
        }
    }

    public static var sampleMailboxManager: MailboxManager = {
        let fakeToken = ApiToken(
            accessToken: "",
            expiresIn: 0,
            refreshToken: "",
            scope: "",
            tokenType: "",
            userId: 0,
            expirationDate: Date(timeIntervalSinceNow: 1_000_000)
        )
        let apiFetcher = MailApiFetcher(token: fakeToken, delegate: PreviewHelperRefreshTokenDelegate())
        let contactManager = ContactManager(userId: 0, apiFetcher: apiFetcher)
        return MailboxManager(mailbox: sampleMailbox,
                              apiFetcher: apiFetcher,
                              contactManager: contactManager)
    }()

    public static let sampleMailbox = Mailbox(uuid: "",
                                              email: "test@example.com",
                                              emailIdn: "",
                                              mailbox: "",
                                              linkId: 0,
                                              mailboxId: 0,
                                              hostingId: 0,
                                              isPrimary: true,
                                              isPasswordValid: true,
                                              isLocked: false,
                                              isSpamFilter: false,
                                              isLimited: false,
                                              isFree: false,
                                              dailyLimit: 999,
                                              aliases: ["test@example.com", "test@example.ch"].toRealmList())

    public static let sampleFolder = Folder(remoteId: "",
                                            path: "Folder",
                                            name: "Folder",
                                            isFavorite: false,
                                            separator: "",
                                            children: [])

    public static let sampleThread = Thread(uid: "",
                                            messages: [sampleMessage],
                                            unseenMessages: 1,
                                            from: [sampleRecipient1],
                                            to: [sampleRecipient2],
                                            subject: "Test thread",
                                            internalDate: SentryDebug.knownDebugDate,
                                            date: SentryDebug.knownDebugDate,
                                            hasAttachments: true,
                                            hasDrafts: false,
                                            flagged: true,
                                            answered: true,
                                            forwarded: true)

    public static let sampleMessage = Message(uid: "",
                                              msgId: "",
                                              subject: "Test message",
                                              priority: .normal,
                                              internalDate: SentryDebug.knownDebugDate,
                                              date: SentryDebug.knownDebugDate,
                                              size: 0,
                                              from: [sampleRecipient1],
                                              to: [sampleRecipient2],
                                              cc: [],
                                              bcc: [],
                                              replyTo: [],
                                              body: nil,
                                              attachments: [sampleAttachment],
                                              dkimStatus: .notSigned,
                                              resource: "",
                                              downloadResource: "",
                                              swissTransferUuid: nil,
                                              folderId: "",
                                              references: nil,
                                              preview: "Lorem ipsum dolor sit amen",
                                              answered: false,
                                              isDraft: false,
                                              hasAttachments: true,
                                              seen: false,
                                              scheduled: false,
                                              forwarded: false,
                                              flagged: false,
                                              hasUnsubscribeLink: true,
                                              acknowledge: "pending")

    public static let sampleMessages = Array(
        repeating: PreviewHelper.sampleMessage,
        count: 6
    )

    public static let sampleRecipientWithMessage = [PreviewHelper.sampleRecipient1: sampleMessage]

    public static let samplePresentableBody = PresentableBody(message: sampleMessage)

    public static let sampleRecipient1 = Recipient(email: "from@example.com", name: "John Doe")
    public static let sampleRecipient2 = Recipient(email: "to@example.com", name: "Alice Bobber")
    public static let sampleRecipient3 = Recipient(email: "cc@example.com", name: "")
    public static let sampleRecipient4 = Recipient(email: "lucien.cheval@ik.com", name: "Lucien Cheval")
    public static let sampleRecipient5 = Recipient(email: "ellen.ripley@domaine.ch", name: "ellen.ripley@domaine.ch")

    public static let sampleRecipients = [
        sampleRecipient1,
        sampleRecipient2,
        sampleRecipient3,
        sampleRecipient4,
        sampleRecipient5
    ]
    public static let sampleRecipientsList = sampleRecipients.toRealmList()

    public static let sampleAttachment = Attachment(
        uuid: "",
        partId: "",
        mimeType: "unknown",
        size: 0,
        name: "Test attachment.bin",
        disposition: .attachment
    )

    public static let sampleMergedContact = MergedContact(email: "mergedContact@example.com", local: nil, remote: nil)

    public static let sampleUser = UserProfile(
        id: 1,
        displayName: "John Appleseed",
        firstName: "John",
        lastName: "Appleseed",
        email: "mobiletest@ik.me"
    )

    public static let sampleDraftContentManager = DraftContentManager(
        draftLocalUUID: "",
        messageReply: nil,
        mailboxManager: sampleMailboxManager
    )

    public static let sampleCalendarEvent = CalendarEvent(
        id: 42,
        type: .event,
        title: "Réunion Produit",
        location: "Salle Théâtre",
        isFullDay: false,
        start: .now,
        end: .now.addingTimeInterval(120),
        status: nil,
        attendees: sampleAttendees.toRealmList()
    )

    public static let sampleAttendees = [sampleAttendee1, sampleAttendee2, sampleAttendee3, sampleAttendee4]

    public static let sampleAttendee1 = Attendee(email: "lucien.cheval@ik.com", name: "Lucien Cheval", isOrganizer: true)
    public static let sampleAttendee2 = Attendee(
        email: "test@example.com",
        name: "test@example.com",
        isOrganizer: false,
        state: .yes
    )
    public static let sampleAttendee3 = Attendee(
        email: "ellen.ripley@domaine.ch",
        name: "Ellen Ripley",
        isOrganizer: false,
        state: .maybe
    )
    public static let sampleAttendee4 = Attendee(
        email: "steph.guy@domaine.ch",
        name: "Steph Guy",
        isOrganizer: false,
        state: .no
    )

    public static let reactions = [
        MessageReaction(
            reaction: "🙂",
            authors: [ReactionAuthor(recipient: sampleRecipient1, bimi: nil)],
            hasUserReacted: true
        ),
        MessageReaction(
            reaction: "😊",
            authors: [ReactionAuthor(recipient: sampleRecipient1, bimi: nil)],
            hasUserReacted: false
        )
    ].toRealmList()

    public static let uiReactions = [
        UIReaction(
            reaction: "🙂",
            authors: [UIReactionAuthor(recipient: sampleRecipient1, bimi: nil)],
            hasUserReacted: true
        ),
        UIReaction(
            reaction: "😊",
            authors: [UIReactionAuthor(recipient: sampleRecipient1, bimi: nil)],
            hasUserReacted: false
        )
    ]
}
