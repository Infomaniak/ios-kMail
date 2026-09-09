/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import AppIntents
import Contacts
import CoreSpotlight
import Foundation
import MailResources

extension IntentPerson {
    init(recipient: Recipient) {
        self.init(
            identifier: .applicationDefined(recipient.id),
            name: .displayName(recipient.name),
            handle: .init(emailAddress: recipient.email)
        )
    }

    var recipient: Recipient? {
        guard case .emailAddress(let email) = handle?.value else { return nil }

        switch name {
        case .displayName(let displayName):
            return Recipient(email: email, name: displayName)
        case .components(let components):
            return Recipient(email: email, name: components.formatted(.name(style: .long)))
        default:
            return Recipient(email: email, name: MailResourcesStrings.Localizable.unknownRecipientTitle)
        }
    }

    var searchableName: String? {
        switch name {
        case .displayName(let displayName):
            return displayName
        case .components(let components):
            return components.formatted(.name(style: .long))
        default:
            return nil
        }
    }

    var emailAddress: String? {
        guard case .emailAddress(let emailAddress) = handle?.value else {
            return nil
        }
        return emailAddress
    }

    var searchablePerson: CSPerson? {
        guard searchableName != nil || emailAddress != nil else {
            return nil
        }

        return CSPerson(
            displayName: searchableName,
            handles: emailAddress.map { [$0] } ?? [],
            handleIdentifier: CNContactEmailAddressesKey
        )
    }
}
