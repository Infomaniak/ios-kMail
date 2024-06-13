/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import SwiftUI

/// Something that can asynchronously load a contact, and update views accordingly
@MainActor
public final class AvatarViewModel: ObservableObject {
    @Published public var displayablePerson: CommonContact

    /// Something not using the MainActor
    private struct AvatarLoader {
        var contactConfiguration: ContactConfiguration

        /// Async get contact method
        func getContact() async -> CommonContact {
            return CommonContactCache.getOrCreateContact(contactConfiguration: contactConfiguration)
        }
    }

    public init(contactConfiguration: ContactConfiguration) {
        // early exit on empty value
        if case .emptyContact = contactConfiguration {
            displayablePerson = CommonContact.emptyContact
            return
        }

        // early exit on wrapped value
        if case .contact(let wrappedContact) = contactConfiguration {
            displayablePerson = wrappedContact
            return
        }

        // early exit on contact cached
        if let cached = CommonContactCache.getContactFromCache(contactConfiguration: contactConfiguration) {
            displayablePerson = cached
            return
        }

        // Load contact in background, empty contact in the meantime
        displayablePerson = CommonContact.emptyContact
        Task {
            let loader = AvatarLoader(contactConfiguration: contactConfiguration)
            self.displayablePerson = await loader.getContact()
        }
    }
}
