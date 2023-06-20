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

public class Recipient: EmbeddedObject, Codable {
    @Persisted public var email: String
    @Persisted public var name: String

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

    public var isCurrentUser: Bool {
        return AccountManager.instance.currentAccount?.user.email == email
    }

    public var isMe: Bool {
        return AccountManager.instance.currentMailboxManager?.mailbox.email == email
    }

    public lazy var nameComponents: (givenName: String, familyName: String?) = {
        let name = contact?.name ?? (name.isEmpty ? email : name)

        let components = name.components(separatedBy: .whitespaces)
        let givenName = components[0]
        let familyName = components.count > 1 ? components[1] : nil
        return (givenName, familyName)
    }()

    public lazy var formattedName: String = {
        if isMe {
            return MailResourcesStrings.Localizable.contactMe
        }
        return contact?.name ?? (name.isEmpty ? email : name)
    }()

    public lazy var formattedShortName: String = {
        if Constants.isEmailAddress(formattedName) {
            return email.components(separatedBy: "@").first ?? email
        }
        return isMe ? MailResourcesStrings.Localizable.contactMe : nameComponents.givenName.removePunctuation
    }()

    public var color: UIColor {
        return contact?.color ?? UIColor.backgroundColor(from: email.hash, with: UIConstants.avatarColors)
    }

    public lazy var initials: String = {
        let initials = [nameComponents.givenName, nameComponents.familyName]
            .map { $0?.removePunctuation.first }
            .compactMap { $0 }
            .map { "\($0)" }
        return initials.joined().uppercased()
    }()

    public lazy var contact: MergedContact? = AccountManager.instance.currentContactManager?.getContact(for: self)

    public var htmlDescription: String {
        let emailString = "&lt;\(email)&gt;"
        if name.isEmpty {
            return emailString
        } else {
            return "\(name) \(emailString)"
        }
    }

    public func isSameRecipient(as recipient: Recipient) -> Bool {
        return email == recipient.email && name == recipient.name
    }
}

extension Recipient: AvatarDisplayable {
    public var avatarImageRequest: ImageRequest? {
        guard !(isCurrentUser && isMe) else {
            return AccountManager.instance.currentAccount.user.avatarImageRequest
        }
        return contact?.avatarImageRequest
    }

    public var initialsBackgroundColor: UIColor {
        color
    }
}
