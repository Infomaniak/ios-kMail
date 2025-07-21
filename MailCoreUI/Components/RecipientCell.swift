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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreSwiftUI
import MailCore
import MailResources
import SwiftUI

public struct RecipientCellModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
    }
}

public extension View {
    func recipientCellModifier() -> some View {
        modifier(RecipientCellModifier())
    }
}

public struct RecipientCell: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let title: String
    let subtitle: String
    let avatarConfiguration: ContactConfiguration
    let avatarSize: CGFloat

    let highlight: String?
    let bimi: Bimi?

    public static let defaultAvatarSize: CGFloat = 40

    public init(
        recipient: Recipient,
        highlight: String? = nil,
        bimi: Bimi? = nil,
        avatarSize: CGFloat = Self.defaultAvatarSize,
        contextUser: UserProfile,
        contextMailboxManager: MailboxManager
    ) {
        title = recipient.name
        subtitle = recipient.email
        avatarConfiguration =
            .correspondent(
                correspondent: recipient,
                associatedBimi: bimi,
                contextUser: contextUser,
                contextMailboxManager: contextMailboxManager
            )
        self.highlight = highlight
        self.bimi = bimi
        self.avatarSize = avatarSize
    }

    public init(
        contactConfiguration: ContactConfiguration,
        title: String,
        subtitle: String,
        highlight: String? = nil,
        bimi: Bimi? = nil,
        avatarSize: CGFloat = Self.defaultAvatarSize,
    ) {
        self.title = title
        self.subtitle = subtitle
        avatarConfiguration = contactConfiguration

        self.highlight = highlight
        self.bimi = bimi
        self.avatarSize = avatarSize
    }

    public var body: some View {
        HStack(spacing: IKPadding.mini) {
            AvatarView(
                mailboxManager: mailboxManager,
                contactConfiguration: avatarConfiguration,
                size: avatarSize
            )
            .accessibilityHidden(true)

            if title.isEmpty || title == subtitle {
                header(subtitle)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    header(title)
                    Text(highlightedAttributedString(from: subtitle))
                        .textStyle(.bodySecondary)
                }
            }
        }
        .recipientCellModifier()
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
}

#Preview {
    RecipientCell(
        recipient: PreviewHelper.sampleRecipient1,
        contextUser: PreviewHelper.sampleUser,
        contextMailboxManager: PreviewHelper.sampleMailboxManager
    )
}
