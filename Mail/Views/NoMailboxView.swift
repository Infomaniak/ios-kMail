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

import MailResources
import SwiftUI

struct NoMailboxView: View {
    @Environment(\.window) var window

    var body: some View {
        VStack(spacing: 0) {
            Image(resource: MailResourcesAsset.logoText)
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)

            Spacer()

            VStack(spacing: 16) {
                Text(MailResourcesStrings.Localizable.noMailboxTitle)
                    .textStyle(.header2)
                Text(MailResourcesStrings.Localizable.noMailboxDescription)
                    .textStyle(.bodySecondary)
            }
            .multilineTextAlignment(.center)

            Spacer()

            LargeButton {
                // TODO: Add email address
                showWorkInProgressSnackBar()
            } label: {
                Label(MailResourcesStrings.Localizable.buttonAddEmailAddress, systemImage: "plus")
            }
            Button {
                (window?.windowScene?.delegate as? SceneDelegate)?.showLoginView()
            } label: {
                Text(MailResourcesStrings.Localizable.buttonLogInDifferentAccount)
                    .textStyle(.bodyMediumAccent)
            }
        }
    }
}

struct NoMailboxView_Previews: PreviewProvider {
    static var previews: some View {
        NoMailboxView()
    }
}
