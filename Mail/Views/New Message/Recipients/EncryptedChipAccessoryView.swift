/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import MailResources
import SwiftUI

struct EncryptedChipAccessoryView: View {
    let isEncrypted: Bool
    let badgeWidth = 8.0

    var body: some View {
        if isEncrypted {
            MailResourcesAsset.lockSquareFill.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundStyle(MailResourcesAsset.iconSovereignBlueColor)
        } else {
            MailResourcesAsset.unlockSquareFill.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundStyle(MailResourcesAsset.textSecondaryColor)
                .overlay {
                    Circle()
                        .fill(MailResourcesAsset.orangeColor.swiftUIColor)
                        .frame(width: badgeWidth)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .offset(x: 2 + badgeWidth / 2)
                }
        }
    }
}

#Preview {
    VStack {
        EncryptedChipAccessoryView(isEncrypted: true)
        EncryptedChipAccessoryView(isEncrypted: false)
    }
}
