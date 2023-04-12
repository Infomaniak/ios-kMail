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
import InfomaniakLogin
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct AccountCellView: View {
    @Environment(\.window) private var window

    let account: Account
    @Binding var selectedUserId: Int?

    private var isSelected: Bool {
        return selectedUserId == account.userId
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)

            RoundedRectangle(cornerRadius: 10)
                .stroke(MailResourcesAsset.elementsColor.swiftUIColor, lineWidth: 1)

            VStack {
                Button {
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .account, name: "switch")
                    withAnimation {
                        selectedUserId = selectedUserId == account.userId ? nil : account.userId
                        (window?.windowScene?.delegate as? SceneDelegate)?.switchAccount(account)
                    }
                } label: {
                    AccountHeaderCell(account: account, isSelected: Binding(get: {
                        isSelected
                    }, set: {
                        selectedUserId = $0 ? account.userId : nil
                    }))
                    .padding(.leading, 8)
                    .padding(.trailing, 16)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct AccountHeaderCell: View {
    let account: Account
    @Binding var isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            AvatarView(avatarDisplayable: account.user, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.user.displayName)
                    .textStyle(.bodyMedium)
                Text(account.user.email)
                    .textStyle(.bodySecondary)
            }
            .lineLimit(1)

            Spacer()

            if isSelected {
                MailResourcesAsset.check.swiftUIImage
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.accentColor)
            }
        }
    }
}

struct AccountCellView_Previews: PreviewProvider {
    static var previews: some View {
        AccountCellView(
            account: Account(apiToken: ApiToken(
                accessToken: "",
                expiresIn: .max,
                refreshToken: "",
                scope: "",
                tokenType: "",
                userId: 0,
                expirationDate: .distantFuture
            )),
            selectedUserId: .constant(nil)
        )
    }
}
