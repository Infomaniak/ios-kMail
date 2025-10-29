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
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct ContactActionView: View {
    @LazyInjectService private var snackbarPresenter: IKSnackBarPresentable

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var mainViewState: MainViewState

    let recipient: Recipient
    let action: Action

    var body: some View {
        Button {
            handleAction(action)
        } label: {
            ActionButtonLabel(action: action)
        }
    }

    // MARK: - Actions

    private func handleAction(_ action: Action) {
        switch action {
        case .writeEmailAction:
            writeEmail()
        case .addContactsAction:
            dismiss()
            addToContacts()
        case .copyEmailAction:
            dismiss()
            copyEmail()
        default:
            return
        }
    }

    private func writeEmail() {
        dismiss()
        mainViewState.composeMessageIntent = .writeTo(recipient: recipient, originMailboxManager: mailboxManager)
    }

    private func addToContacts() {
        Task {
            await tryOrDisplayError {
                try await mailboxManager.contactManager.addContact(recipient: recipient)
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarContactSaved)
            }
        }
    }

    private func copyEmail() {
        UIPasteboard.general.string = recipient.email
        snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarEmailCopiedToClipboard)
    }
}
