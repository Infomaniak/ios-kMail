/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct BlockSenderView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var selectedRecipient: Recipient?

    let reportedMessages: [Message]
    let origin: ActionOrigin

    private var recipients: [Recipient] {
        reportedMessages
            .compactMap(\.from.first)
            .filter { recipient in
                !recipient.isMe(currentMailboxEmail: mailboxManager.mailbox.email)
            }
            .reduce(into: [String: Recipient]()) { uniqueRecipients, recipient in
                if let existingRecipient = uniqueRecipients[recipient.email] {
                    if (existingRecipient.name.isEmpty) && !(recipient.name.isEmpty) {
                        uniqueRecipients[recipient.email] = recipient
                    }
                } else {
                    uniqueRecipients[recipient.email] = recipient
                }
            }
            .values
            .sorted {
                let name1 = ($0.name.isEmpty ? $0.email : $0.name).lowercased()
                let name2 = ($1.name.isEmpty ? $1.email : $1.name).lowercased()
                return name1 < name2
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(MailResourcesStrings.Localizable.blockAnExpeditorTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, value: .medium)

            ForEach(recipients) { recipient in
                Button {
                    selectedRecipient = recipient
                    matomo.track(eventWithCategory: .blockUserAction, name: "selectUser")
                } label: {
                    RecipientCell(recipient: recipient)
                        .padding(.horizontal, value: .medium)
                        .padding(.vertical, value: .small)
                }
                if recipient != recipients.last {
                    IKDivider()
                }
            }
        }
        .customAlert(item: $selectedRecipient) { recipient in
            ConfirmationBlockRecipientView(
                recipient: recipient,
                reportedMessages: getMessages(for: recipient),
                origin: origin,
                onDismiss: { dismiss() }
            )
        }
    }

    private func getMessages(for recipient: Recipient) -> [Message] {
        return reportedMessages.filter { message in
            message.from.contains(where: { $0 == recipient })
        }
    }
}

#Preview {
    BlockSenderView(reportedMessages: PreviewHelper.sampleMessages, origin: .floatingPanel(source: .threadList))
        .accentColor(AccentColor.pink.primary.swiftUIColor)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
