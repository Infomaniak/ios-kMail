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

import InfomaniakCore
import InfomaniakDI
import MailCore
import MailResources
import NavigationBackport
import SwiftUI

struct SelectMailboxView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var mailboxInfosManager: MailboxInfosManager

    @State var selectedMailbox: Mailbox?

    @Binding var composeMessageIntent: ComposeMessageIntent

    var accounts: [Account] {
        accountManager.accounts.sorted { lhs, rhs in
            if lhs.userId == accountManager.currentUserId {
                return true
            } else {
                return lhs.user.displayName.compare(rhs.user.displayName) == .orderedAscending
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            accentColor.mailTo.swiftUIImage

            Text(MailResourcesStrings.Localizable.mailToTitle(""))
                .textStyle(.header1)
                .multilineTextAlignment(.center)
                .padding(.bottom, value: .medium)

            Text(MailResourcesStrings.Localizable.mailToDescription)
                .textStyle(.bodySmallSecondary)
                .padding(.bottom, value: .regular)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                AccountMailboxesListView(accounts: accounts, selectedMailbox: selectedMailbox, selectMailbox: selectMailbox)
            }

            Button(MailResourcesStrings.Localizable.buttonContinue) {
                mailboxHasBeenSelected()
            }
            .buttonStyle(.ikPlain)
            .ikButtonFullWidth(true)
        }
        .padding(.horizontal, value: .medium)
        .mailboxCellStyle(.account)
        .onAppear {
            selectedMailbox = accountManager.currentMailboxManager?.mailbox
            if accountManager.accounts.count == 1 && mailboxInfosManager.getMailboxes().count == 1 {
                mailboxHasBeenSelected()
            }
        }
    }

    private func mailboxHasBeenSelected() {
        guard let selectedMailbox, let mailboxManager = accountManager.getMailboxManager(for: selectedMailbox) else {
            // TODO: display snackbar
            return
        }
        switch composeMessageIntent.type {
        case .new:
            composeMessageIntent = .new(originMailboxManager: mailboxManager)
        case .mailTo(let mailToURLComponents):
            composeMessageIntent = .mailTo(mailToURLComponents: mailToURLComponents, originMailboxManager: mailboxManager)
        default:
            break
        }
    }

    private func selectMailbox(_ mailbox: Mailbox) {
        guard mailbox.isAvailable else {
            // TODO: Display snackbar
            return
        }

        selectedMailbox = mailbox
    }
}

#Preview {
    SelectMailboxView(composeMessageIntent: .constant(.new()))
}

enum TestTest {
    case test
}
