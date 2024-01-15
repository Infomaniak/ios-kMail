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

import MailCore
import SwiftUI

struct RecipientCellModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
    }
}

extension View {
    func recipientCellModifier() -> some View {
        modifier(RecipientCellModifier())
    }
}

struct RecipientCell: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let recipient: Recipient
    var highlight: String?

    var body: some View {
        HStack(spacing: UIPadding.small) {
            AvatarView(
                mailboxManager: mailboxManager,
                contactConfiguration: .correspondent(
                    correspondent: recipient.freezeIfNeeded(),
                    contextMailboxManager: mailboxManager
                ),
                size: 40
            )
            .accessibilityHidden(true)

            if recipient.name.isEmpty {
                Text(highlightedAttributedString(from: recipient.email))
                    .textStyle(.bodyMedium)
            } else {
                VStack(alignment: .leading) {
                    Text(highlightedAttributedString(from: recipient.name))
                        .textStyle(.bodyMedium)
                    Text(highlightedAttributedString(from: recipient.email))
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
    RecipientCell(recipient: PreviewHelper.sampleRecipient1)
}

#Preview {
    RecipientCell(recipient: PreviewHelper.sampleRecipient3)
}
