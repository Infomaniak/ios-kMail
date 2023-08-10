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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct ContactActionsView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var mailboxManager: MailboxManager

    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    @State private var writtenToRecipient: Recipient?

    let recipient: Recipient
    private var actions: [Action] {
        let isRemoteContact = mailboxManager.contactManager.getContact(for: recipient)?.remote != nil

        if isRemoteContact {
            return [.writeEmailAction, .copyEmailAction]
        } else {
            return [.writeEmailAction, .addContactsAction, .copyEmailAction]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.actionsViewSpacing) {
            ContactActionsHeaderView(displayablePerson: CommonContact(
                recipient: recipient,
                contextMailboxManager: mailboxManager
            ))
            .padding(.horizontal, 16)

            ForEach(actions) { action in
                if action != actions.first {
                    IKDivider()
                }

                // FIXME: target for now is only message, not contact
                /*ActionView(action: action) {
                    if let matomoName = action.matomoName {
                        matomo.track(eventWithCategory: .contactActions, name: matomoName)
                    }
                    handleAction(action)
                }
                .padding(.horizontal, UIConstants.actionsViewCellHorizontalPadding)*/
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, UIConstants.actionsViewHorizontalPadding)
        .sheet(item: $writtenToRecipient) { writtenToRecipient in
            ComposeMessageView.writingTo(recipient: writtenToRecipient, mailboxManager: mailboxManager)
        }
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ContactActionsView"])
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
        writtenToRecipient = recipient
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

struct ContactActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ContactActionsView(recipient: PreviewHelper.sampleRecipient1)
            .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
