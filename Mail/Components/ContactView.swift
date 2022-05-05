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

    private struct ContactAction: Hashable {
        let name: String
        let image: UIImage

        static let writeEmailAction = ContactAction(
            name: MailResourcesStrings.writeAnEmail,
            image: MailResourcesAsset.ecrire.image
        )
        static let addContactsAction = ContactAction(
            name: MailResourcesStrings.addToContacts,
            image: MailResourcesAsset.singleNeutralActionsAdd.image
        )
        static let copyEmailAction = ContactAction(
            name: MailResourcesStrings.copyEmailAddress,
            image: MailResourcesAsset.commonFileDouble.image
        )
    }

    private let actions: [ContactAction] = [
        .writeEmailAction, .addContactsAction, .copyEmailAction
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if let contact = recipient.contact {
                    ContactImage(contact: contact)
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading) {
                        Text(contact.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(MailResourcesAsset.primaryTextColor.color))
                        Text(contact.email)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(MailResourcesAsset.secondaryTextColor.color))
                    }
                } else {
                    RecipientImage(recipient: recipient, size: 32)
                    VStack(alignment: .leading) {
                        Text(recipient.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(MailResourcesAsset.primaryTextColor.color))
                        Text(recipient.email)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(MailResourcesAsset.secondaryTextColor.color))
                    }
                }
            }
            .frame(height: 40)

            ForEach(actions, id: \.self) { action in
                HStack {
                    Image(uiImage: action.image)
                        .foregroundColor(Color(MailResourcesAsset.infomaniakColor.color))
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

    private func handleAction(_ action: ContactAction) {
        switch action {
        case .writeEmailAction:
            // TODO: handle writeEmail action
            return
        case .addContactsAction:
            // TODO: handle addContacts action
            return
        case .copyEmailAction:
            // TODO: handle copyEmail action
            return
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
