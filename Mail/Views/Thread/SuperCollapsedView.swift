/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

struct SuperCollapsedView: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .strokeBorder(MailResourcesAsset.textFieldColor.swiftUIColor, lineWidth: 1)
                .background(MailResourcesAsset.backgroundCardSelectedColor.swiftUIColor)
                .frame(height: 8)

            Button(action: action) {
                Text(MailResourcesStrings.Localizable.superCollapsedBlock(count))
                    .textStyle(.bodyAccent)
                    .padding(.vertical, value: .small)
                    .padding(.horizontal, value: .large)
                    .frame(minHeight: 40)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(MailResourcesAsset.textFieldColor.swiftUIColor, lineWidth: 1)
                    .background(MailResourcesAsset.backgroundCardSelectedColor.swiftUIColor, in: .rect(cornerRadius: 16))
            )
        }
    }
}

#Preview {
    SuperCollapsedView(count: 5, action: {})
}
