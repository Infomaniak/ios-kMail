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
            return "Me"
        }
        return contact?.name ?? (name.isEmpty ? email : name)
    }

    public var color: Color {
        if let contact = contact {
            return Color(hex: contact.color)
        }
        return .gray
    }

    public var initials: String {
        return (contact?.name ?? name)
            .components(separatedBy: .whitespaces)
            .compactMap(\.first)
            .prefix(2)
            .map { "\($0)" }
            .joined()
            .uppercased()
    }

    public var contact: MergedContact? {
        AccountManager.instance.currentContactManager?.getContact(for: email)
    }
}
