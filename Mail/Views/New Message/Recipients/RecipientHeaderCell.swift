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

import DesignSystem
import MailCore
import MailCoreUI
import MailResources
import Nuke
import SwiftUI

struct RecipientHeaderCell: View {
    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var loadedImage: Image?
    @State private var iconImage: Image?

    let recipient: Recipient
    var highlight: String?
    var bimi: Bimi?

    private var avatarConfiguration: ContactConfiguration {
        ContactConfiguration.correspondent(
            correspondent: recipient,
            associatedBimi: bimi,
            contextUser: currentUser.value,
            contextMailboxManager: mailboxManager
        )
    }

    private var displayablePerson: CommonContact {
        CommonContactCache.getOrCreateContact(contactConfiguration: avatarConfiguration)
    }

    static let defaultAvatarSize: CGFloat = 40

    var body: some View {
        let title = recipient.name
        let subtitle = recipient.email

        Button {} label: {
            if title.isEmpty || title == subtitle {
                header(subtitle)
            } else {
                header(title)
                Text(highlightedAttributedString(from: subtitle))
                    .textStyle(.bodySecondary)
            }

            if let loadedImage {
                loadedImage
                    .resizable()
                    .frame(maxWidth: Self.defaultAvatarSize)
            } else if let iconImage {
                iconImage
            }
        }
        .task {
            if let imageRequest = getAvatarImageRequest() {
                let task = ImagePipeline.shared.imageTask(with: imageRequest)
                guard let uiImage = try? await task.image else { return }
                loadedImage = Image(uiImage: uiImage)
            }
            await getIconImage()
        }
    }

    private func header(_ title: String) -> some View {
        HStack(spacing: IKPadding.mini) {
            Text(highlightedAttributedString(from: title))
                .textStyle(.bodyMedium)

            if bimi?.shouldDisplayBimi == true {
                MailResourcesAsset.checkmarkAuthentication
                    .iconSize(.medium)
            }
        }
    }

    private func highlightedAttributedString(from data: String) -> AttributedString {
        var attributedString = AttributedString(data)
        guard let highlight else { return attributedString }

        if let range = attributedString.range(of: highlight, options: .caseInsensitive) {
            attributedString[range].foregroundColor = .accentColor
        }
        return attributedString
    }

    private func getAvatarImageRequest() -> ImageRequest? {
        guard let currentToken = mailboxManager.apiFetcher.currentToken else { return nil }
        return displayablePerson.avatarImageRequest.authenticatedRequestIfNeeded(
            token: currentToken,
            processors: [.circle()]
        )
    }

    private func getIconImage() async {
        guard #available(iOS 16.0, *) else {
            iconImage = nil
            return
        }
        guard
            let renderedImage = ImageRenderer(
                content: AvatarView(
                    mailboxManager: mailboxManager,
                    contactConfiguration: avatarConfiguration,
                    size: Self.defaultAvatarSize
                )
            )
            .uiImage
        else { return }
        iconImage = Image(uiImage: renderedImage)
    }
}
