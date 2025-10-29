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

import Foundation
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct SelectableComposeMailbox {
    let user: UserProfile
    let mailbox: Mailbox
    let mailboxManager: MailboxManager
}

final class SelectComposeMailboxViewModel: ObservableObject {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var mailboxInfosManager: MailboxInfosManager
    @LazyInjectService private var snackbarPresenter: IKSnackBarPresentable

    @Published private(set) var selectedMailbox: SelectableComposeMailbox?
    @Published private(set) var defaultSelectableMailbox: SelectableComposeMailbox?
    @Published private(set) var selectionMade = false
    @Published private(set) var userProfiles = [UserProfile]()

    private(set) var composeMessageIntent: Binding<ComposeMessageIntent>

    init(composeMessageIntent: Binding<ComposeMessageIntent>) {
        self.composeMessageIntent = composeMessageIntent
    }

    @MainActor
    func initProfilesSelectDefaultAccountAndMailbox() async {
        await listProfiles()
        initDefaultAccountAndMailbox()
    }

    @MainActor
    private func listProfiles() async {
        let fetchedUserProfiles = await accountManager.accounts
            .asyncMap { await self.accountManager.userProfileStore.getUserProfile(id: $0.userId) }
            .compactMap { $0 }
            .sorted { lhs, rhs in
                if (lhs.id == accountManager.currentUserId) != (rhs.id == accountManager.currentUserId) {
                    return lhs.id == accountManager.currentUserId
                } else {
                    return lhs.displayName < rhs.displayName
                }
            }

        userProfiles = fetchedUserProfiles
    }

    private func initDefaultAccountAndMailbox() {
        guard let defaultMailbox = accountManager.currentMailboxManager?.mailbox,
              let mailboxManager = accountManager.getMailboxManager(for: defaultMailbox),
              let user = userProfiles.first(where: { $0.id == defaultMailbox.userId }) else {
            return
        }

        defaultSelectableMailbox = SelectableComposeMailbox(user: user, mailbox: defaultMailbox, mailboxManager: mailboxManager)
        if accountManager.accounts.count == 1 && mailboxInfosManager.getMailboxes().count == 1 {
            validateMailboxChoice(defaultMailbox)
        }
    }

    func selectMailbox(_ mailbox: Mailbox) {
        guard mailbox.isAvailable,
              let user = userProfiles.first(where: { $0.id == mailbox.userId }),
              let mailboxManager = accountManager.getMailboxManager(for: mailbox.mailboxId, userId: mailbox.userId) else {
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorMailboxUnavailable)
            return
        }
        selectedMailbox = SelectableComposeMailbox(user: user, mailbox: mailbox, mailboxManager: mailboxManager)
        selectionMade = true
    }

    func validateMailboxChoice(_ selectedMailbox: Mailbox?) {
        guard let mailbox = selectedMailbox,
              let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorUnknown)
            return
        }

        switch composeMessageIntent.wrappedValue.type {
        case .new:
            composeMessageIntent.wrappedValue = .new(originMailboxManager: mailboxManager, fromExtension: true)
        case .mailTo(let mailToURLComponents):
            composeMessageIntent.wrappedValue = .mailTo(
                mailToURLComponents: mailToURLComponents,
                originMailboxManager: mailboxManager
            )
        default:
            break
        }
    }
}
