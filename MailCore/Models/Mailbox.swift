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
import RealmSwift

public class Mailbox: Object, Codable, Identifiable {
    @Persisted(primaryKey: true) public var objectId = ""
    /*
     Mailbox data
     */
    @Persisted public var uuid: String
    @Persisted public var email: String
    @Persisted public var emailIdn: String
    @Persisted public var mailbox: String
    @Persisted public var realMailbox: String
    @Persisted public var linkId: Int
    @Persisted public var mailboxId: Int
    @Persisted public var hostingId: Int
    @Persisted public var isPrimary: Bool
    @Persisted public var passwordStatus: String
    @Persisted public var isPasswordValid: Bool
    @Persisted public var isValid: Bool
    @Persisted public var isLocked: Bool
    @Persisted public var hasSocialAndCommercialFiltering: Bool
//    @Persisted public var hasMoveSpam: Bool?
    @Persisted public var showConfigModal: Bool
    @Persisted public var forceResetPassword: Bool
    @Persisted public var mdaVersion: String
    @Persisted public var isLimited: Bool
    @Persisted public var isFree: Bool
    @Persisted public var dailyLimit: Int
    @Persisted public var unseenMessages = 0
    @Persisted public var userId = 0 {
        didSet {
            objectId = MailboxInfosManager.getObjectId(mailboxId: mailboxId, userId: userId)
        }
    }
    @Persisted public var permissions: MailboxPermissions?
    @Persisted public var quotas: Quotas?

    public var id: Int {
        return mailboxId
    }

    enum CodingKeys: String, CodingKey {
        case uuid
        case email
        case emailIdn
        case mailbox
        case realMailbox
        case linkId
        case mailboxId
        case hostingId
        case isPrimary
        case passwordStatus
        case isPasswordValid
        case isValid
        case isLocked
        case hasSocialAndCommercialFiltering
        case showConfigModal
        case forceResetPassword
        case mdaVersion
        case isLimited
        case isFree
        case dailyLimit
        case unseenMessages
    }

    public convenience init(
        uuid: String,
        email: String,
        emailIdn: String,
        mailbox: String,
        realMailbox: String,
        linkId: Int,
        mailboxId: Int,
        hostingId: Int,
        isPrimary: Bool,
        passwordStatus: String,
        isPasswordValid: Bool,
        isValid: Bool,
        isLocked: Bool,
        hasSocialAndCommercialFiltering: Bool,
        showConfigModal: Bool,
        forceResetPassword: Bool,
        mdaVersion: String,
        isLimited: Bool,
        isFree: Bool,
        dailyLimit: Int
    ) {
        self.init()

        self.uuid = uuid
        self.email = email
        self.emailIdn = emailIdn
        self.mailbox = mailbox
        self.realMailbox = realMailbox
        self.linkId = linkId
        self.mailboxId = mailboxId
        self.hostingId = hostingId
        self.isPrimary = isPrimary
        self.passwordStatus = passwordStatus
        self.isPasswordValid = isPasswordValid
        self.isValid = isValid
        self.isLocked = isLocked
        self.hasSocialAndCommercialFiltering = hasSocialAndCommercialFiltering
        self.showConfigModal = showConfigModal
        self.forceResetPassword = forceResetPassword
        self.mdaVersion = mdaVersion
        self.isLimited = isLimited
        self.isFree = isFree
        self.dailyLimit = dailyLimit
    }
}
