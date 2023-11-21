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

import InfomaniakCore
import MailCore
import MailResources
import NukeUI
import SwiftUI

/// A view that displays an avatar linked to a Contact.
struct AvatarView: View {
    /// Optional as this view can be displayed from a context without a mailboxManager available
    let mailboxManager: MailboxManager?

    /// The size of the avatar view
    let size: CGFloat

    /// A view model for async loading of contacts
    @StateObject private var viewModel: AvatarViewModel

    init(mailboxManager: MailboxManager?, contactConfiguration: ContactConfiguration, size: CGFloat = 28) {
        self.mailboxManager = mailboxManager
        self.size = size

        _viewModel = StateObject(wrappedValue: AvatarViewModel(contactConfiguration: contactConfiguration))
    }

    var body: some View {
        Group {
            let displayablePerson = viewModel.displayablePerson
            if let mailboxManager,
               let currentToken = mailboxManager.apiFetcher.currentToken,
               let avatarImageRequest = displayablePerson.avatarImageRequest.authenticatedRequestIfNeeded(token:
                   currentToken) {
                LazyImage(request: avatarImageRequest) { state in
                    if let image = state.image {
                        ContactImage(image: image, size: size)
                    } else {
                        InitialsView(
                            initials: displayablePerson.formatted(style: .initials),
                            color: displayablePerson.color,
                            size: size
                        )
                    }
                }
            } else {
                InitialsView(initials: displayablePerson.formatted(style: .initials), color: displayablePerson.color, size: size)
            }
        }
        .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionUserAvatar)
    }
}
