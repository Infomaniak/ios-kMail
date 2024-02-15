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
import MailResources
import SwiftUI

struct MailToView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @EnvironmentObject private var mailboxManager: MailboxManager

    let currentMailbox: Mailbox?
    let mailTo: String?

    var body: some View {
        VStack(spacing: 0) {
            accentColor.mailTo.swiftUIImage

            Text(MailResourcesStrings.Localizable.mailToTitle(mailTo ?? ""))
                .textStyle(.header1)
                .multilineTextAlignment(.center)
                .padding(.bottom, value: .medium)

            Text(MailResourcesStrings.Localizable.mailToDescription)
                .textStyle(.bodySmallSecondary)
                .padding(.bottom, value: .regular)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                if let currentMailbox {
                    MailboxCell(mailbox: currentMailbox, isSelected: true)
                        .mailboxCellStyle(.account)
                }

                ForEachMailboxView(
                    userId: mailboxManager.account.userId,
                    excludedMailboxIds: [currentMailbox?.mailboxId].compactMap { $0 }
                ) { mailbox in
                    MailboxCell(mailbox: mailbox)
                        .mailboxCellStyle(.account)
                }
            }

            Button(MailResourcesStrings.Localizable.buttonContinue) {}
                .buttonStyle(.ikPlain)
                .ikButtonFullWidth(true)
        }
        .padding(.horizontal, value: .medium)
    }
}

#Preview {
    MailToView(currentMailbox: PreviewHelper.sampleMailbox, mailTo: PreviewHelper.sampleRecipient1.email)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
