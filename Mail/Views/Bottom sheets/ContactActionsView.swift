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
import MailCore
import MailResources
import SwiftUI

struct ContactActionsView: View {
    var recipient: Recipient
    var isRemoteContact: Bool
    @ObservedObject var bottomSheet: MessageBottomSheet
    @ObservedObject var sheet: MessageSheet

    private struct ContactAction: Hashable {
        let name: String
        let image: UIImage

        static let writeEmailAction = ContactAction(
            name: MailResourcesStrings.Localizable.contactActionWriteEmail,
            image: MailResourcesAsset.pencil.image
        )
        static let addContactsAction = ContactAction(
            name: MailResourcesStrings.Localizable.contactActionAddToContacts,
            image: MailResourcesAsset.addUser.image
        )
        static let copyEmailAction = ContactAction(
            name: MailResourcesStrings.Localizable.contactActionCopyEmailAddress,
            image: MailResourcesAsset.duplicate.image
        )
    }

    private var actions: [ContactAction] {
        if isRemoteContact {
            return [.writeEmailAction, .copyEmailAction]
        }
        return [.writeEmailAction, .addContactsAction, .copyEmailAction]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                RecipientImage(recipient: recipient, size: 32)
                VStack(alignment: .leading) {
                    Text(recipient.contact?.name ?? recipient.title)
                        .textStyle(.header3)
                    Text(recipient.contact?.email ?? recipient.email)
                        .textStyle(.bodySecondary)
                }
            }
            .padding(.bottom, 8)

            ForEach(actions, id: \.self) { action in
                Button {
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
    }

    // MARK: - Actions

    private func handleAction(_ action: ContactAction) {
        switch action {
        case .writeEmailAction:
            writeEmail()
        case .addContactsAction:
            addToContacts()
        case .copyEmailAction:
            copyEmail()
        default:
            return
        }
        bottomSheet.close()
    }

    private func writeEmail() {
        sheet.state = .write(to: recipient)
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
        ContactActionsView(recipient: PreviewHelper.sampleRecipient1,
                    isRemoteContact: false,
                    bottomSheet: MessageBottomSheet(),
                    sheet: MessageSheet())
    }
}
