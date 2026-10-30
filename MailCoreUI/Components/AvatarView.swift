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
import InfomaniakCoreSwiftUI
import MailCore
import MailResources
import NukeUI
import SwiftUI

extension AvatarView: Equatable {
    public static func == (lhs: AvatarView, rhs: AvatarView) -> Bool {
        return lhs.mailboxManager == rhs.mailboxManager
            && lhs.contactConfiguration.id == rhs.contactConfiguration.id
    }
}

public struct AvatarView: View {
    @ObservedObject private var viewModel: AvatarViewModel

    private let mailboxManager: MailboxManager?
    private let contactConfiguration: ContactConfiguration

    private var displayablePerson: CommonContact {
        viewModel.displayablePerson
    }

    public init(mailboxManager: MailboxManager?, contactConfiguration: ContactConfiguration) {
        self.mailboxManager = mailboxManager
        self.contactConfiguration = contactConfiguration

        // We use an ObservedObject instead of a StateObject because SwiftUI doesn't want to respect Equatable
        _viewModel = ObservedObject(wrappedValue: AvatarViewModel(contactConfiguration: contactConfiguration.freezeIfNeeded()))
    }

    public var body: some View {
        Group {
            if case .emptyContact = contactConfiguration {
                IconAvatarView(type: .unknownRecipient)
            } else if case .addressBook = contactConfiguration {
                IconAvatarView(type: .addressBook)
            } else if case .groupContact = contactConfiguration {
                IconAvatarView(type: .groupRecipients)
            } else if let avatarImageRequest = getAvatarImageRequest() {
                LazyImage(request: avatarImageRequest) { state in
                    if let image = state.image {
                        AvatarImage(image: image)
                    } else {
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionUserAvatar)
    }

    private var initialsView: some View {
        InitialsView(
            initials: displayablePerson.formatted(style: .initials),
            backgroundColor: displayablePerson.color,
            foregroundColor: MailResourcesAsset.backgroundSecondaryColor.swiftUIColor
        )
    }

    private func getAvatarImageRequest() -> ImageRequest? {
        guard let mailboxManager, let currentToken = mailboxManager.apiFetcher.currentToken else { return nil }
        return displayablePerson.avatarImageRequest.authenticatedRequestIfNeeded(token: currentToken)
    }
}
