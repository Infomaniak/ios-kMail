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
import MailResources

struct AddRecipientCell: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    let recipientEmail: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accentColor.primary.swiftUIColor)
                .frame(width: 40, height: 40)
                .overlay {
                    MailResourcesAsset.userBold.swiftUIImage
                        .resizable()
                        .foregroundColor(accentColor.onAccent.swiftUIColor)
                        .frame(width: 24, height: 24)
                }

            VStack(alignment: .leading, spacing: 0) {
                Text(MailResourcesStrings.Localizable.addUnknownRecipientTitle)
                    .textStyle(.bodyMedium)
                Text(recipientEmail)
                    .textStyle(.bodySecondary)
            }

            Spacer()
        }
        .lineLimit(1)
    }
}

struct AddRecipientCell_Previews: PreviewProvider {
    static var previews: some View {
        AddRecipientCell(recipientEmail: "")
    }
}
