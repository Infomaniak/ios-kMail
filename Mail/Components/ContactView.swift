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

struct ContactView: View {
    var recipient: Recipient
    @ObservedObject var bottomSheet: MessageBottomSheet

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

    private let actions: [ContactAction] = [
        .writeEmailAction, .addContactsAction, .copyEmailAction
    ]

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
            .frame(height: 40)

            ForEach(actions, id: \.self) { action in
                Button {
                    handleAction(action)
                } label: {
                    HStack {
                        Image(uiImage: action.image)
                        Text(action.name)
                            .textStyle(.body)
                    }
                }
                .frame(height: 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing], 24)
        .padding(.top, 16)
    }

    private func writeEmail() {
        // TODO: handle writeEmail action
    }

    private func addToContacts() {
        // TODO: handle addContacts action
    }

    private func copyEmail() {
        UIPasteboard.general.string = recipient.email
        bottomSheet.close()
    }

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
    }
}

struct ContactView_Previews: PreviewProvider {
    static var previews: some View {
        ContactView(recipient: PreviewHelper.sampleRecipient1, bottomSheet: MessageBottomSheet())
    }
}
