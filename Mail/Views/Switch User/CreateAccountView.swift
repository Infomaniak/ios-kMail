//
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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct CreateAccountView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            accentColor.createAccountImage.swiftUIImage
                .resizable()
                .scaledToFit()
                .padding(.bottom, 24)

            Text(MailResourcesStrings.Localizable.newAccountTitle)
                .textStyle(.header1)
                .multilineTextAlignment(.center)

            HStack {
                    Text(MailResourcesStrings.Localizable.newAccountStorageMail)
                        .textStyle(.labelMediumAccent)
                        .padding()
                            .background(accentColor.secondary.swiftUIColor)
                            .clipShape(Capsule())
                            .multilineTextAlignment(.center)
                Text(MailResourcesStrings.Localizable.newAccountStorageDrive)
                    .textStyle(.labelMediumAccent)
                    .padding()
                        .background(accentColor.secondary.swiftUIColor)
                        .clipShape(Capsule())
                        .multilineTextAlignment(.center)
            }
            .fixedSize(horizontal: true, vertical: true)
            .padding(.bottom, 12)

            Text(MailResourcesStrings.Localizable.newAccountDescription)
                .textStyle(.bodySmallSecondary)
                .padding(.bottom, 12)

            MailButton(label: MailResourcesStrings.Localizable.buttonCreate) {
                //TODO: add action on press
            }.mailButtonFullWidth(true)
        }
        .padding(.horizontal, 24)
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView()
    }
}
