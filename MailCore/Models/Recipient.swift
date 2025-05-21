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
import Nuke
import RealmSwift
import SwiftRegex
import SwiftUI

public extension URLComponents {
    func getQueryItem(named name: String) -> String? {
        return queryItems?.first { $0.name == name }?.value
    }
}

public struct RecipientHolder {
    var from = [Recipient]()
    var to = [Recipient]()
    var cc = [Recipient]()
    var bcc = [Recipient]()
}

public enum RecipientError: Error {
    case invalidEmail
    case duplicateContact
}

public final class RecipientsList: EmbeddedObject, Encodable {
    @Persisted private var recipients: RealmSwift.List<Recipient>

    public var count: Int {
        recipients.count
    }

    override public init() {
        super.init()
    }

    public convenience init(recipients: [Recipient]) {
        self.init()
        self.recipients = recipients.toRealmList()
    }

    public func append(recipients: [Recipient]) {
        self.recipients.append(objectsIn: recipients)
    }

    public func contains(where precidate: (Recipient) -> Bool) -> Bool {
        return recipients.contains(where: precidate)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: recipients)
    }
}

public final class Recipient: EmbeddedObject, Correspondent, Codable {
    @Persisted public var email: String
    @Persisted public var name: String
    @Persisted public var isAddedByMe = false

    enum CodingKeys: String, CodingKey {
        case email
        case name
    }

    public convenience init(email: String, name: String) {
        self.init()
        self.email = email
        self.name = name
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)
    }

    public static func createListUsing(from urlComponents: URLComponents, name: String) -> [Recipient] {
        return createListUsing(listOfAddresses: urlComponents.getQueryItem(named: name))
    }

    public static func createListUsing(listOfAddresses: String?) -> [Recipient] {
        guard let addresses = listOfAddresses?.components(separatedBy: CharacterSet(charactersIn: ",;")) else { return [] }

        var recipients = [Recipient]()
        for address in addresses {
            if Constants.isEmailAddress(address) {
                recipients.append(Recipient(email: address, name: ""))
            } else if let match = Regex(pattern: "(.+)<(.+)>")?.matches(in: address).first,
                      match.count >= 3, Constants.isEmailAddress(match[2]) {
                recipients.append(Recipient(email: match[2], name: match[1].removingPercentEncoding ?? match[1]))
            }
        }

        return recipients
    }

    private static let mailerDeamonRegex = Regex(pattern: "mailer-daemon@(?:.+.)?infomaniak.ch")

    public func isExternal(mailboxManager: MailboxManager) -> Bool {
        guard let externalMailInfo = mailboxManager.mailbox.externalMailInfo,
              externalMailInfo.externalMailFlagEnabled else { return false }

        // if the email address is added manually by me, it's not considered as an extern
        guard !isAddedByMe else { return false }

        let trustedDomains = externalMailInfo.domains
        let isKnownDomain = trustedDomains.contains { domain in
            return email.hasSuffix(domain)
        }

        let isMailerDeamon: Bool
        if let regex = Self.mailerDeamonRegex {
            isMailerDeamon = !regex.firstMatch(in: email).isEmpty
        } else {
            isMailerDeamon = false
        }

        let isAnAlias = mailboxManager.mailbox.aliases.contains(email)

        let isContact = !(mailboxManager.contactManager.frozenContacts(matching: email, fetchLimit: nil, sorted: nil)).isEmpty

        return !isKnownDomain && !isMailerDeamon && !isAnAlias && !isContact
    }

    public func isSameRecipient(recipient: Recipient) -> Bool {
        return email == recipient.email
    }
}

extension Recipient: ContactAutocompletable {
    public var contactId: String {
        return id
    }

    public var autocompletableName: String {
        return name
    }

    public func isSameContactAutocompletable(as contactAutoCompletable: any ContactAutocompletable) -> Bool {
        return contactId == contactAutoCompletable.contactId
    }
}
