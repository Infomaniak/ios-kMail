/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct ComposeMessageContactCell<Cell: View>: View {
    let recipient: Recipient
    let onMentionSelected: (Recipient) -> Void
    @ViewBuilder let cell: () -> Cell

    var body: some View {
        Button {
            withAnimation {
                onMentionSelected(recipient)
            }
        } label: {
            cell()
                .padding(.horizontal, value: .medium)
                .padding(.vertical, value: .mini)
        }
    }
}

struct ComposeMessageContactList: View {
    @EnvironmentObject private var mailboxManager: MailboxManager
    @Environment(\.currentUser) private var currentUser

    let mentionQuery: String
    let mentionSuggestions: [Recipient]
    let onMentionSelected: (Recipient) -> Void

    private var normalizedMentionQuery: String {
        let lowerCasedQuery = mentionQuery.lowercased()
        return lowerCasedQuery.applyingTransform(.stripDiacritics, reverse: false) ?? lowerCasedQuery
    }

    private var unknownRecipient: Recipient? {
        guard EmailChecker(email: mentionQuery).validate(),
              !mentionSuggestions.contains(where: { $0.email.lowercased() == mentionQuery.lowercased() }) else {
            return nil
        }

        return Recipient(email: mentionQuery, name: mentionQuery).freezeIfNeeded()
    }

    var body: some View {
        VStack {
            ForEach(mentionSuggestions) { recipient in
                ComposeMessageContactCell(recipient: recipient, onMentionSelected: onMentionSelected) {
                    RecipientCell(
                        recipient: recipient,
                        highlight: normalizedMentionQuery,
                        contextUser: currentUser.value,
                        contextMailboxManager: mailboxManager
                    )
                }
            }

            if let unknownRecipient {
                ComposeMessageContactCell(recipient: unknownRecipient, onMentionSelected: onMentionSelected) {
                    UnknownRecipientCell(email: unknownRecipient.email)
                }
            }
        }
    }
}

#Preview {
    ComposeMessageContactList(mentionQuery: "", mentionSuggestions: []) { _ in }
}

#Preview {
    ComposeMessageContactCell(recipient: Recipient(
        email: PreviewHelper.sampleMailbox.email,
        name: PreviewHelper.sampleMailbox.email
    )) { recipient in
        print(recipient.email)
    } cell: {
        Text("Preview Cell")
    }
}
