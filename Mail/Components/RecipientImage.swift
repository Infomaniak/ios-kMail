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

struct RecipientImage: View {
    var recipient: Recipient
    var size: CGFloat = 40

    @State private var image = Image(resource: MailResourcesAsset.placeholderAvatar)
    @State private var showContactImage = false

    var body: some View {
        Group {
            if showContactImage {
                ContactImage(image: image, size: size)
            } else {
                ZStack {
                    Circle()
                        .fill(recipient.color)
                    Text(recipient.initials)
                        .font(.system(size: size * 0.5, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: size, height: size)
            }
        }
        .task {
            if recipient.isCurrentUser {
                showContactImage = true
                image = await AccountManager.instance.currentAccount.user.getAvatar()
            } else if let contact = recipient.contact, contact.hasAvatar {
                showContactImage = true
                contact.getAvatar { contactImage in
                    image = Image(uiImage: contactImage)
                }
            } else if recipient.initials.isEmpty {
                showContactImage = true
            }
        }
    }
}

struct RecipientImage_Previews: PreviewProvider {
    static var previews: some View {
        RecipientImage(recipient: PreviewHelper.sampleRecipient1)
    }
}
