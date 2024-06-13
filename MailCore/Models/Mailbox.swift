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
    @Persisted public var linkId: Int
    @Persisted public var mailboxId: Int
    @Persisted public var hostingId: Int
    @Persisted public var isPrimary: Bool
    @Persisted public var passwordStatus: String
    @Persisted public var isPasswordValid: Bool
    @Persisted public var isValid: Bool
    @Persisted public var isLocked: Bool
    @Persisted public var hasSocialAndCommercialFiltering: Bool
    @Persisted public var showConfigModal: Bool
    @Persisted public var forceResetPassword: Bool
    @Persisted public var mdaVersion: String
    @Persisted public var isLimited: Bool
    @Persisted public var isFree: Bool
    @Persisted public var dailyLimit: Int
    @Persisted public var unseenMessages = 0
    @Persisted public var remoteUnseenMessages: Int
    @Persisted public var aliases: List<String>
    @Persisted public var userId = 0 {
        didSet {
            objectId = MailboxInfosManager.getObjectId(mailboxId: mailboxId, userId: userId)
        }
    }

    @Persisted public var permissions: MailboxPermissions?
    @Persisted public var quotas: Quotas?
    @Persisted public var externalMailInfo: ExternalMailInfo?

    public var id: String {
        return uuid
    }

    public var isAvailable: Bool {
        return isPasswordValid && !isLocked
    }

    public var notificationTopicName: String {
        return "mailbox-\(mailboxId)"
    }

    enum CodingKeys: String, CodingKey {
        case uuid
        case email
        case emailIdn
        case mailbox
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
        case remoteUnseenMessages = "unseenMessages"
        case aliases
    }

    override public init() {
        super.init()
    }

    public convenience init(
        uuid: String,
        email: String,
        emailIdn: String,
        mailbox: String,
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
        dailyLimit: Int,
        aliases: List<String>
    ) {
        self.init()

        self.uuid = uuid
        self.email = email
        self.emailIdn = emailIdn
        self.mailbox = mailbox
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
        self.aliases = aliases
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        email = try container.decode(String.self, forKey: .email)
        emailIdn = try container.decode(String.self, forKey: .emailIdn)
        mailbox = try container.decode(String.self, forKey: .mailbox)
        linkId = try container.decode(Int.self, forKey: .linkId)
        mailboxId = try container.decode(Int.self, forKey: .mailboxId)
        hostingId = try container.decode(Int.self, forKey: .hostingId)
        isPrimary = try container.decode(Bool.self, forKey: .isPrimary)
        passwordStatus = try container.decode(String.self, forKey: .passwordStatus)
        isPasswordValid = try container.decode(Bool.self, forKey: .isPasswordValid)
        isValid = try container.decode(Bool.self, forKey: .isValid)
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
        hasSocialAndCommercialFiltering = try container.decode(Bool.self, forKey: .hasSocialAndCommercialFiltering)
        showConfigModal = try container.decode(Bool.self, forKey: .showConfigModal)
        forceResetPassword = try container.decode(Bool.self, forKey: .forceResetPassword)
        mdaVersion = try container.decode(String.self, forKey: .mdaVersion)
        isLimited = try container.decode(Bool.self, forKey: .isLimited)
        isFree = try container.decode(Bool.self, forKey: .isFree)
        dailyLimit = try container.decode(Int.self, forKey: .dailyLimit)
        remoteUnseenMessages = try container.decode(Int.self, forKey: .remoteUnseenMessages)
        // Waiting for WS issue #5508 to remove this and go back to default initializer
        aliases = (try? container.decode(List<String>.self, forKey: .aliases)) ?? List<String>()
    }
}

public extension [Mailbox] {
    func webmailSorted() -> [Mailbox] {
        return sorted {
            if $0.isPrimary {
                return true
            } else if $1.isPrimary {
                return false
            }

            return $0.email < $1.email
        }
    }
}
