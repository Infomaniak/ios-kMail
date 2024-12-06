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

import InfomaniakCore
import MailCore
import MailResources
import NukeUI
import SwiftUI

extension AvatarView: Equatable {
    public static func == (lhs: AvatarView, rhs: AvatarView) -> Bool {
        return lhs.mailboxManager == rhs.mailboxManager
            && lhs.size == rhs.size
            && lhs.contactConfiguration.id == rhs.contactConfiguration.id
    }
}

/// A view that displays an avatar linked to a Contact.
public struct AvatarView: View {
    /// A view model for async loading of contacts
    @ObservedObject private var viewModel: AvatarViewModel

    /// Optional as this view can be displayed from a context without a mailboxManager available
    private let mailboxManager: MailboxManager?

    /// The size of the avatar view
    private let size: CGFloat

    /// The configuration associated to this view
    private let contactConfiguration: ContactConfiguration

    private var displayablePerson: CommonContact {
        viewModel.displayablePerson
    }

    public init(mailboxManager: MailboxManager?, contactConfiguration: ContactConfiguration, size: CGFloat = 28) {
        self.mailboxManager = mailboxManager
        self.size = size
        self.contactConfiguration = contactConfiguration

        // We use an ObservedObject instead of a StateObject because SwiftUI doesn't want to respect Equatable
        _viewModel = ObservedObject(wrappedValue: AvatarViewModel(contactConfiguration: contactConfiguration.freezeIfNeeded()))
    }

    public var body: some View {
        Group {
            if case .emptyContact = contactConfiguration {
                UnknownRecipientView(size: size)
            } else if case .addressBook = contactConfiguration {
                GroupRecipientsView(size: size)
            } else if case .groupContact = contactConfiguration {
                GroupRecipientsView(size: size)
            } else if let avatarImageRequest = getAvatarImageRequest() {
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

    private func getAvatarImageRequest() -> ImageRequest? {
        guard let mailboxManager, let currentToken = mailboxManager.apiFetcher.currentToken else { return nil }
        return displayablePerson.avatarImageRequest.authenticatedRequestIfNeeded(token: currentToken)
    }
}
