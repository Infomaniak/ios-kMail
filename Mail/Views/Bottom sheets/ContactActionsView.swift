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
    @EnvironmentObject var mailboxManager: MailboxManager
    @Environment(\.dismiss) var dismiss
    @LazyInjectService private var matomo: MatomoUtils

    @State private var writtenToRecipient: Recipient?

    private let recipient: Recipient
    private let actions: [ContactAction]

    init(recipient: Recipient) {
        self.recipient = recipient
        let isRemoteContact = AccountManager.instance.currentContactManager?.getContact(for: recipient)?.remote != nil
        if isRemoteContact {
            actions = [.writeEmailAction, .copyEmailAction]
        } else {
            actions = [.writeEmailAction, .addContactsAction, .copyEmailAction]
        }
    }

    private struct ContactAction: Hashable {
        let name: String
        let image: UIImage
        let matomoName: String

        static let writeEmailAction = ContactAction(
            name: MailResourcesStrings.Localizable.contactActionWriteEmail,
            image: MailResourcesAsset.pencil.image,
            matomoName: "writeEmail"
        )
        static let addContactsAction = ContactAction(
            name: MailResourcesStrings.Localizable.contactActionAddToContacts,
            image: MailResourcesAsset.userAdd.image,
            matomoName: "addToContacts"
        )
        static let copyEmailAction = ContactAction(
            name: MailResourcesStrings.Localizable.contactActionCopyEmailAddress,
            image: MailResourcesAsset.duplicate.image,
            matomoName: "copyEmailAddress"
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                AvatarView(avatarDisplayable: recipient, size: 32)
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    Text(recipient, format: .recipient(currentEmailContext: mailboxManager.mailbox.email))
                        .textStyle(.bodyMedium)
                    Text(recipient.contact?.email ?? recipient.email)
                        .textStyle(.bodySecondary)
                }
            }
            .padding(.bottom, 8)
            .accessibilityElement(children: .combine)

            ForEach(actions, id: \.self) { action in
                Button {
                    matomo.track(eventWithCategory: .contactActions, name: action.matomoName)
                    handleAction(action)
                } label: {
                    HStack(spacing: 20) {
                        Image(uiImage: action.image)
                        Text(action.name)
                            .textStyle(.body)
                    }
                }
                if action != actions.last {
                    IKDivider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .sheet(item: $writtenToRecipient) { writtenToRecipient in
            ComposeMessageView.writingTo(recipient: writtenToRecipient, mailboxManager: mailboxManager)
        }
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ContactActionsView"])
    }

    // MARK: - Actions

    private func handleAction(_ action: ContactAction) {
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
                try await AccountManager.instance.currentContactManager?.addContact(recipient: recipient)
                IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackbarContactSaved)
            }
        }
    }

    private func copyEmail() {
        UIPasteboard.general.string = recipient.email
        IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackbarEmailCopiedToClipboard)
    }
}

struct ContactActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ContactActionsView(recipient: PreviewHelper.sampleRecipient1)
            .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
