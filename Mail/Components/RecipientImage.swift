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
import SwiftUI

struct RecipientImage: View {
    var recipient: Recipient?
    var size: CGFloat = 40

    var body: some View {
        if recipient.isCurrentUser,
           let url = URL(string: AccountManager.instance.currentAccount.user.avatar) {
            AsyncImage(url: url) { image in
                image.resizable()
            } placeholder: {
                Color.gray
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else if let contact = recipient.contact, contact.hasAvatar {
            ContactImage(contact: contact)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else if recipient.initials.isEmpty {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: size, height: size)
                .foregroundColor(recipient.color)
                .background(Color.white)
                .clipShape(Circle())
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
}

struct RecipientImage_Previews: PreviewProvider {
    static var previews: some View {
        RecipientImage(recipient: PreviewHelper.sampleRecipient1)
    }
}
