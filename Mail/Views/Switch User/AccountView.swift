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

struct AccountView: View {
    @State private var avatarImage = MailResourcesAsset.placeholderAvatar.image
    @State private var user: UserProfile! = AccountManager.instance.currentAccount.user

    var body: some View {
        VStack {
            // Image
            Image(uiImage: avatarImage)
                .resizable()
                .frame(width: 110, height: 110)
                .clipShape(Circle())

            // Email
            Text(user.email)
                .textStyle(.header2Normal)

            // BUtton changer de compte
            Button {
                // TODO: - Change account action
            } label: {
                // TODO: - Traduction
                Text("Changer de compte")
                    .textStyle(.button)
            }

            // Button email associé au compte
            SeparatorView(withPadding: false, fullWidth: true)
            HStack {
                // TODO: - Traduction
                Text("Adresses e-mail associées au compte")
                Spacer()
                Image(systemName: "chevron.right")
                    .frame(width: 12, height: 12)
            }
            SeparatorView(withPadding: false, fullWidth: true)

            // Appareils liste
            // TODO: - Appareil list

            // Button supprimer compte
            Button {
                // TODO: - Delete account
            } label: {
                Text("Supprimer mon compte")
                    .textStyle(.button)
            }

            // Button me déconnecter de ce compte
            Button {
                // TODO: - Disconnect account
            } label: {
                // TODO: - Traduction
                Text("Me déconnecter de ce compte")
                    .textStyle(.button)
            }
        }
        .onAppear {
            user.getAvatar(size: CGSize(width: 110, height: 110)) { image in
                self.avatarImage = image
            }
        }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
