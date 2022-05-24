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
    @EnvironmentObject var card: MessageCard

    private struct ContactAction: Hashable {
        let name: String
        let image: UIImage

        static let writeEmailAction = ContactAction(
            name: MailResourcesStrings.contactActionWriteEmail,
            image: MailResourcesAsset.ecrire.image
        )
        static let addContactsAction = ContactAction(
            name: MailResourcesStrings.contactActionAddToContacts,
            image: MailResourcesAsset.singleNeutralActionsAdd.image
        )
        static let copyEmailAction = ContactAction(
            name: MailResourcesStrings.contactActionCopyEmailAddress,
            image: MailResourcesAsset.commonFileDouble.image
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
                    Text(recipient.contact?.name ?? recipient.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MailResourcesAsset.primaryTextColor)
                    Text(recipient.contact?.email ?? recipient.email)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(MailResourcesAsset.secondaryTextColor)
                }
            }
            .frame(height: 40)

            ForEach(actions, id: \.self) { action in
                HStack {
                    Image(uiImage: action.image)
                        .foregroundColor(MailResourcesAsset.infomaniakColor)
                    Text(action.name)
                }
                .frame(height: 40)
                .onTapGesture {
                    handleAction(action)
                }
            }
        }
        .padding([.leading, .trailing, .bottom], 24)
        .padding(.top, 31)
    }

    private func writeEmail() {
        // TODO: handle writeEmail action
    }

    private func addToContacts() {
        // TODO: handle addContacts action
    }

    private func copyEmail() {
        UIPasteboard.general.string = recipient.email
        card.cardDismissal = false
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
        ContactView(recipient: PreviewHelper.sampleRecipient1)
    }
}
