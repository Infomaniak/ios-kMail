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
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    let title: String
    let subtitle: String
    let avatarConfiguration: ContactConfiguration

    let highlight: String?

    // TODO: Change contactConfig
    public init(recipient: Recipient, contactConfiguration: ContactConfiguration = .emptyContact, highlight: String? = nil) {
        title = recipient.name
        subtitle = recipient.email
        avatarConfiguration = contactConfiguration

        self.highlight = highlight
    }

    // TODO: Change contactConfig + subtitle
    public init(
        contact: any ContactAutocompletable,
        contactConfiguration: ContactConfiguration = .emptyContact,
        highlight: String? = nil
    ) {
        title = contact.name
        if let email = contact.email {
            subtitle = email
        } else {
            subtitle = "Nom de l'organisation"
        }
        avatarConfiguration = contactConfiguration

        self.highlight = highlight
    }

    public var body: some View {
        HStack(spacing: IKPadding.mini) {
            AvatarView(
                mailboxManager: mailboxManager,
                contactConfiguration: avatarConfiguration,
                size: 40
            )
            .accessibilityHidden(true)

            if title.isEmpty {
                Text(highlightedAttributedString(from: subtitle))
                    .textStyle(.bodyMedium)
            } else {
                VStack(alignment: .leading) {
                    Text(highlightedAttributedString(from: title))
                        .textStyle(.bodyMedium)
                    Text(highlightedAttributedString(from: subtitle))
                        .textStyle(.bodySecondary)
                }
            }
        }
        .recipientCellModifier()
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
    RecipientCell(recipient: PreviewHelper.sampleRecipient1, contactConfiguration: .emptyContact)
}

#Preview {
    RecipientCell(recipient: PreviewHelper.sampleRecipient3, contactConfiguration: .emptyContact)
}
