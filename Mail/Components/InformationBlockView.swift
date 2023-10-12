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

struct InformationBlockView: View {
    let icon: Image
    let message: String
    var dismissHandler: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: UIPadding.small) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(.tint)

            Text(message)
                .textStyle(.body)

            if let dismissHandler {
                CloseButton(size: .medium, dismissHandler: dismissHandler)
            }
        }
        .padding(value: .regular)
        .background(MailResourcesAsset.textFieldColor.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    InformationBlockView(icon: MailResourcesAsset.lightBulbShine.swiftUIImage, message: "Tip")
}
