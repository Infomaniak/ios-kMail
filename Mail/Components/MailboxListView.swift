/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct MailboxListView: View {
    @Environment(\.currentUser) private var currentUser

    let currentMailbox: Mailbox?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Text(MailResourcesStrings.Localizable.buttonAccountAssociatedEmailAddresses)
                    .textStyle(.bodySmallSecondary)
                    .padding([.top, .bottom, .leading], value: .medium)
                    .frame(maxWidth: .infinity, alignment: .leading)

                NavigationLink {
                    AddMailboxView()
                } label: {
                    IKIcon(MailResourcesAsset.addCircle)
                        .foregroundStyle(.tint)
                        .padding(value: .medium)
                        .accessibilityLabel(MailResourcesStrings.Localizable.buttonAddEmailAddress)
                }
            }

            if let currentMailbox {
                MailboxCell(mailbox: currentMailbox, isSelected: true)
                    .mailboxCellStyle(.account)
                    .padding(value: .medium)
            }

            ForEachMailboxView(
                userId: currentUser.value.id,
                excludedMailboxIds: [currentMailbox?.mailboxId].compactMap { $0 }
            ) { mailbox in
                MailboxCell(mailbox: mailbox)
                    .mailboxCellStyle(.account)
                    .padding(value: .medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MailboxListView(currentMailbox: PreviewHelper.sampleMailbox)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
