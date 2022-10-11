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
import RealmSwift
import SwiftUI

public class Recipient: EmbeddedObject, Codable {
    @Persisted public var email: String
    @Persisted public var name: String

    public convenience init(email: String, name: String) {
        self.init()
        self.email = email
        self.name = name
    }

    public var isCurrentUser: Bool {
        return AccountManager.instance.currentAccount?.user.email == email
    }

    public var title: String {
        if isCurrentUser {
            return MailResourcesStrings.Localizable.contactMe
        }
        return contact?.name.removePunctuation ?? (name.isEmpty ? email : name.removePunctuation)
    }

    public var color: UIColor {
        return contact?.color ?? UserDefaults.shared.accentColor.primary.color
    }

    public var initials: String {
        let nameInitials = (contact?.name ?? name)
            .removePunctuation
            .components(separatedBy: .whitespaces)
            .compactMap(\.first)
        guard let firstLetter = nameInitials.first else {
            if let secondaryInitial = email.first {
                return secondaryInitial.uppercased()
            }
            return ""
        }
        if let secondLetter = nameInitials.last, nameInitials.count > 1 {
            return [firstLetter, secondLetter].map { "\($0)" }.joined().uppercased()
        } else {
            return [firstLetter].map { "\($0)" }.joined().uppercased()
        }
    }

    public var contact: MergedContact? {
        AccountManager.instance.currentContactManager?.getContact(for: self)
    }

    public var htmlDescription: String {
        let emailString = "&lt;\(email)&gt;"
        if name.isEmpty {
            return emailString
        } else {
            return "\(name) \(emailString)"
        }
    }

    public var avatarImage: Image? {
        get async {
            if isCurrentUser {
                return await AccountManager.instance.currentAccount.user.getAvatar()
            } else if let contact = contact,
                      contact.hasAvatar,
                      let uiImage = await contact.avatar {
                return Image(uiImage: uiImage)
            } else {
                return nil
            }
        }
    }

    public var cachedAvatarImage: Image? {
        if !isCurrentUser,
           let contact = contact,
           contact.hasAvatar,
           let uiImage = contact.cachedAvatar {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }
}
