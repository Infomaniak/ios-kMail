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
import InfomaniakNotifications
import RealmSwift

public enum LocalPack: Sendable {
    case myKSuiteFree
    case myKSuitePlus
    case kSuiteFree // = kSuite Essential
    case kSuitePaid // = kSuite Standard | Business | Enterprise
    case starterPack

    init?(mailbox: Mailbox) {
        if mailbox.isFree {
            if mailbox.isLimited {
                self = .myKSuiteFree
            } else {
                self = .myKSuitePlus
            }
        } else if mailbox.isPartOfKSuite {
            if mailbox.isKSuiteEssential {
                self = .kSuiteFree
            } else {
                self = .kSuitePaid
            }
        } else if mailbox.isPartOfStarterPack {
            self = .starterPack
        } else {
            return nil
        }
    }
}

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
    @Persisted public var isPasswordValid: Bool
    @Persisted public var isValidInLDAP: Bool
    @Persisted public var isLocked: Bool
    @Persisted public var isSpamFilter: Bool
    @Persisted public var isLimited: Bool
    @Persisted public var isFree: Bool
    @Persisted public var isPartOfKSuite: Bool
    @Persisted public var isKSuiteEssential: Bool
    @Persisted public var isPartOfStarterPack: Bool
    @Persisted public var dailyLimit: Int
    @Persisted public var ownerOrAdmin: Bool
    @Persisted public var maxStorage: Int64?
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
    @Persisted public var sendersRestrictions: SendersRestrictions?

    public var id: String {
        return uuid
    }

    public var isConsideredLocked: Bool {
        return isLocked || !isValidInLDAP
    }

    public var isAvailable: Bool {
        return isPasswordValid && !isConsideredLocked
    }

    public var notificationTopicName: Topic {
        return Topic(rawValue: "mailbox-\(mailboxId)")
    }

    public var pack: LocalPack? {
        return LocalPack(mailbox: self)
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
        case isPasswordValid
        case isValidInLDAP = "isValid"
        case isLocked
        case isSpamFilter
        case isLimited
        case isFree
        case isKSuiteEssential = "isKsuiteEssential"
        case isPartOfKSuite = "isPartOfKsuite"
        case isPartOfStarterPack
        case dailyLimit
        case ownerOrAdmin
        case maxStorage
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
        isPasswordValid: Bool,
        isValidInLDAP: Bool,
        isLocked: Bool,
        isSpamFilter: Bool,
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
        self.isPasswordValid = isPasswordValid
        self.isValidInLDAP = isValidInLDAP
        self.isLocked = isLocked
        self.isSpamFilter = isSpamFilter
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
        isPasswordValid = try container.decode(Bool.self, forKey: .isPasswordValid)
        isValidInLDAP = try container.decode(Bool.self, forKey: .isValidInLDAP)
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
        isSpamFilter = try container.decode(Bool.self, forKey: .isSpamFilter)
        isLimited = try container.decodeIfPresent(Bool.self, forKey: .isLimited) ?? false
        isFree = try container.decodeIfPresent(Bool.self, forKey: .isFree) ?? false
        isKSuiteEssential = try container.decodeIfPresent(Bool.self, forKey: .isKSuiteEssential) ?? false
        isPartOfKSuite = try container.decodeIfPresent(Bool.self, forKey: .isPartOfKSuite) ?? false
        isPartOfStarterPack = try container.decodeIfPresent(Bool.self, forKey: .isPartOfStarterPack) ?? false
        dailyLimit = try container.decode(Int.self, forKey: .dailyLimit)
        ownerOrAdmin = try container.decodeIfPresent(Bool.self, forKey: .ownerOrAdmin) ?? false
        let maxStorageValue = try container.decodeIfPresent(Int64.self, forKey: .maxStorage)
        maxStorage = maxStorageValue != 0 ? maxStorageValue : nil
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
