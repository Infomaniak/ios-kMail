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
import InfomaniakLogin
import MailCore
import RealmSwift
import SwiftUI

enum PreviewHelper {
    static var sampleMailboxManager: MailboxManager = {
        let apiFetcher = MailApiFetcher()
        let contactManager = ContactManager(userId: 0, apiFetcher: apiFetcher)
        return MailboxManager(account: PreviewHelper.sampleAccount,
                              mailbox: sampleMailbox,
                              apiFetcher: apiFetcher,
                              contactManager: contactManager)
    }()

    static let sampleMailbox = Mailbox(uuid: "",
                                       email: "test@example.com",
                                       emailIdn: "",
                                       mailbox: "",
                                       linkId: 0,
                                       mailboxId: 0,
                                       hostingId: 0,
                                       isPrimary: true,
                                       passwordStatus: "",
                                       isPasswordValid: true,
                                       isValid: true,
                                       isLocked: false,
                                       hasSocialAndCommercialFiltering: false,
                                       showConfigModal: false,
                                       forceResetPassword: false,
                                       mdaVersion: "",
                                       isLimited: false,
                                       isFree: false,
                                       dailyLimit: 999,
                                       aliases: ["test@example.com", "test@example.ch"].toRealmList(),
                                       externalMailFlagEnabled: true)

    static let sampleFolder = Folder(id: "",
                                     path: "Folder",
                                     name: "Folder",
                                     isFavorite: false,
                                     separator: "",
                                     children: [])

    static let sampleThread = Thread(uid: "",
                                     messages: [sampleMessage],
                                     unseenMessages: 1,
                                     from: [sampleRecipient1],
                                     to: [sampleRecipient2],
                                     subject: "Test thread",
                                     date: SentryDebug.knownDebugDate,
                                     hasAttachments: true,
                                     hasDrafts: false,
                                     flagged: true,
                                     answered: true,
                                     forwarded: true)

    static let sampleMessage = Message(uid: "",
                                       msgId: "",
                                       subject: "Test message",
                                       priority: .normal,
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
                                       safeDisplay: false,
                                       hasUnsubscribeLink: true)

    static let samplePresentableBody = PresentableBody(message: sampleMessage)

    static let sampleRecipient1 = Recipient(email: "from@example.com", name: "John Doe")

    static let sampleRecipient2 = Recipient(email: "to@example.com", name: "Alice Bobber")

    static let sampleRecipient3 = Recipient(email: "test@example.com", name: "")

    static let sampleRecipientsList = [sampleRecipient1, sampleRecipient2, sampleRecipient3].toRealmList()

    static let sampleAttachment = Attachment(
        uuid: "",
        partId: "",
        mimeType: "unknown",
        size: 0,
        name: "Test attachment.bin",
        disposition: .attachment
    )

    static let sampleMergedContact = MergedContact(email: "mergedContact@example.com", local: nil, remote: nil)

    static let sampleAccount = Account(apiToken: ApiToken(
        accessToken: "",
        expiresIn: 0,
        refreshToken: "",
        scope: "",
        tokenType: "",
        userId: 0,
        expirationDate: Date()
    ))
}
