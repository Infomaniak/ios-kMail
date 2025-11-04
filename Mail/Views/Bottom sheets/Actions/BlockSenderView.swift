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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct BlockSenderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var selectedRecipient: Recipient?
    @State private var recipients = [Recipient]()

    let recipientsToMessage: [Recipient: Message]
    let origin: ActionOrigin

    var body: some View {
        VStack(spacing: 0) {
            ForEach(recipients) { recipient in
                Button {
                    selectedRecipient = recipient

                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .blockUserAction, name: "selectUser")
                } label: {
                    RecipientCell(recipient: recipient, contextUser: currentUser.value, contextMailboxManager: mailboxManager)
                        .padding(.horizontal, value: .medium)
                        .padding(.vertical, value: .mini)
                }
                if recipient != recipients.last {
                    IKDivider()
                }
            }
        }
        .mailCustomAlert(item: $selectedRecipient) { recipient in
            ConfirmationBlockRecipientView(
                recipients: [recipient],
                reportedMessages: [recipientsToMessage[recipient]!],
                origin: origin
            ) {
                dismiss()
            }
        }
        .onAppear {
            recipients = recipientsToMessage.keys
                .sorted {
                    let name1 = ($0.name.isEmpty ? $0.email : $0.name)
                    let name2 = ($1.name.isEmpty ? $1.email : $1.name)
                    return name1.caseInsensitiveCompare(name2) == .orderedAscending
                }
        }
    }
}

#Preview {
    BlockSenderView(
        recipientsToMessage: PreviewHelper.sampleRecipientWithMessage,
        origin: .floatingPanel(source: .threadList)
    )
    .accentColor(AccentColor.pink.primary.swiftUIColor)
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
