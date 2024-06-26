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
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

final class SelectComposeMailboxViewModel: ObservableObject {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var mailboxInfosManager: MailboxInfosManager
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    @Published private(set) var selectedMailbox: Mailbox?
    @Published private(set) var defaultMailbox: Mailbox?
    @Published private(set) var selectionMade = false

    private(set) var composeMessageIntent: Binding<ComposeMessageIntent>
    private(set) var accounts = [Account]()

    init(composeMessageIntent: Binding<ComposeMessageIntent>) {
        self.composeMessageIntent = composeMessageIntent

        accounts = accountManager.accounts.sorted { lhs, rhs in
            if (lhs.userId == accountManager.currentUserId) != (rhs.userId == accountManager.currentUserId) {
                return lhs.userId == accountManager.currentUserId
            } else {
                return lhs.user.displayName < rhs.user.displayName
            }
        }
    }

    func initDefaultAccountAndMailbox() {
        defaultMailbox = accountManager.currentMailboxManager?.mailbox
        if let defaultMailbox, accountManager.accounts.count == 1 && mailboxInfosManager.getMailboxes().count == 1 {
            validateMailboxChoice(defaultMailbox)
        }
    }

    func selectMailbox(_ mailbox: Mailbox) {
        guard mailbox.isAvailable else {
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorMailboxUnavailable)
            return
        }
        selectedMailbox = mailbox
        selectionMade = true
    }

    func validateMailboxChoice(_ selectedMailbox: Mailbox?) {
        guard let mailbox = selectedMailbox, let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
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
