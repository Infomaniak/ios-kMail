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

public protocol Correspondent: Identifiable where ID == String {
    var email: String { get }
    var name: String { get }

    func freezeIfNeeded() -> Self
}

public extension Correspondent {
    var id: String {
        return name + email
    }

    var htmlDescription: String {
        let emailString = "<\(email)>"
        if name.isEmpty {
            return emailString
        } else {
            return "\(name) \(emailString)"
        }
    }

    func isCurrentUser(currentAccountEmail: String) -> Bool {
        return currentAccountEmail == email
    }

    func isMe(currentMailboxEmail: String) -> Bool {
        return currentMailboxEmail == email
    }

    func isSameCorrespondent(as correspondent: any Correspondent) -> Bool {
        return email == correspondent.email && name == correspondent.name
    }
}
