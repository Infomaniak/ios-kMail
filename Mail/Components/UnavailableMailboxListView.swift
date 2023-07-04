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
import RealmSwift
import SwiftUI

struct UnavailableMailboxListView: View {
    @Environment(\.window) private var window

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @ObservedResults(
        Mailbox.self,
        configuration: MailboxInfosManager.instance.realmConfiguration,
        where: { $0.userId == AccountManager.instance.currentUserId && $0.isPasswordValid == false },
        sortDescriptor: SortDescriptor(keyPath: \Mailbox.mailboxId)
    ) private var passwordBlockedMailboxes

    @ObservedResults(
        Mailbox.self,
        configuration: MailboxInfosManager.instance.realmConfiguration,
        where: { $0.userId == AccountManager.instance.currentUserId && $0.isLocked == true },
        sortDescriptor: SortDescriptor(keyPath: \Mailbox.mailboxId)
    ) private var lockedMailboxes

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            if !passwordBlockedMailboxes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(MailResourcesStrings.Localizable.blockedPasswordTitlePlural)
                    ForEach(passwordBlockedMailboxes) { mailbox in
                        MailboxCell(mailbox: mailbox)
                            .mailboxCellStyle(.setPassword)
                    }
                }
            }

            if !lockedMailboxes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(MailResourcesStrings.Localizable.lockedMailboxTitlePlural)
                    ForEach(lockedMailboxes) { mailbox in
                        MailboxesManagementButtonView(
                            icon: MailResourcesAsset.envelope,
                            text: mailbox.email,
                            isSelected: false,
                            isInMaintenance: false
                        ) {}
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 24)
    }
}

struct UnavailableMailboxListView_Previews: PreviewProvider {
    static var previews: some View {
        UnavailableMailboxListView()
    }
}
