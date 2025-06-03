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

import DesignSystem
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct UnavailableMailboxListView: View {
    @ObservedResults var passwordBlockedMailboxes: Results<Mailbox>
    @ObservedResults var lockedMailboxes: Results<Mailbox>

    init(currentUserId: Int) {
        _passwordBlockedMailboxes = ObservedResults(
            Mailbox.self,
            configuration: {
                @InjectService var mailboxInfosManager: MailboxInfosManager
                return mailboxInfosManager.realmConfiguration
            }(),
            where: { UnavailableMailboxListView.filterPasswordBlockedMailboxes($0, for: currentUserId) },
            sortDescriptor: SortDescriptor(keyPath: \Mailbox.mailboxId)
        )
        _lockedMailboxes = ObservedResults(
            Mailbox.self,
            configuration: {
                @InjectService var mailboxInfosManager: MailboxInfosManager
                return mailboxInfosManager.realmConfiguration
            }(),
            where: { UnavailableMailboxListView.filterLockedMailboxes($0, for: currentUserId) },
            sortDescriptor: SortDescriptor(keyPath: \Mailbox.mailboxId)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.huge) {
            if !passwordBlockedMailboxes.isEmpty {
                VStack(alignment: .leading, spacing: IKPadding.small) {
                    Text(MailResourcesStrings.Localizable.blockedPasswordTitle(passwordBlockedMailboxes.count))
                    ForEach(passwordBlockedMailboxes) { mailbox in
                        MailboxCell(mailbox: mailbox)
                            .mailboxCellStyle(.blockedPassword)
                    }
                }
            }

            if !lockedMailboxes.isEmpty {
                VStack(alignment: .leading, spacing: IKPadding.small) {
                    Text(MailResourcesStrings.Localizable.lockedMailboxTitle(lockedMailboxes.count))
                    ForEach(lockedMailboxes) { mailbox in
                        MailboxCell(mailbox: mailbox)
                            .mailboxCellStyle(.locked)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, IKPadding.large)
    }

    private static func filterPasswordBlockedMailboxes(_ mailbox: Query<Mailbox>, for currentUserId: Int) -> Query<Bool> {
        return isCurrentUserMailbox(mailbox, for: currentUserId)
            && mailbox.isPasswordValid == false
            && !isMailboxConsideredLocked(mailbox)
    }

    private static func filterLockedMailboxes(_ mailbox: Query<Mailbox>, for currentUserId: Int) -> Query<Bool> {
        return isCurrentUserMailbox(mailbox, for: currentUserId) && isMailboxConsideredLocked(mailbox)
    }

    private static func isCurrentUserMailbox(_ mailbox: Query<Mailbox>, for currentUserId: Int) -> Query<Bool> {
        return mailbox.userId == currentUserId
    }

    private static func isMailboxConsideredLocked(_ mailbox: Query<Mailbox>) -> Query<Bool> {
        return mailbox.isLocked == true || mailbox.isValidInLDAP == false
    }
}

#Preview {
    UnavailableMailboxListView(currentUserId: 0)
}
