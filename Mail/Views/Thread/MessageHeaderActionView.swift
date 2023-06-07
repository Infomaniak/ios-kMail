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

struct MessageHeaderActionView<Content: View>: View {
    let iconSize: CGFloat = 16
    let icon: Image
    let message: String

    @ViewBuilder var actions: () -> Content

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize)
                        .foregroundColor(MailResourcesAsset.textSecondaryColor)
                    Text(message)
                        .textStyle(.labelSecondary)
                }
                HStack {
                    actions()
                }
                .padding(.leading, iconSize + 8)
            }
            .padding(.horizontal)
            IKDivider()
        }
        .padding(.top)
    }
}

struct MessageHeaderActionView_Previews: PreviewProvider {
    static var previews: some View {
        MessageHeaderActionView(
            icon: MailResourcesAsset.emailActionWarning.swiftUIImage,
            message: MailResourcesStrings.Localizable.alertBlockedImagesDescription
        ) {
            MailButton(label: MailResourcesStrings.Localizable.alertBlockedImagesDisplayContent) {}
                .mailButtonStyle(.smallLink)
        }
    }
}
