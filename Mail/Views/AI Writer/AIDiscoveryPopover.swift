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

struct AIDiscoveryPopover: View {
    @Binding var isShowing: Bool

    var body: some View {
        VStack(spacing: UIPadding.regular) {
            MailResourcesAsset.aiIllustration.swiftUIImage

            Text(MailResourcesStrings.Localizable.aiDiscoveryTitle)
                .textStyle(.header2)

            Text(MailResourcesStrings.Localizable.aiDiscoveryDescription)
                .textStyle(.bodySecondary)
        }
        .padding(.horizontal, value: .regular)
        .padding(.vertical, value: .medium)
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            CloseButton(size: .tiny) {
                isShowing = false
            }
            .padding([.top, .trailing], value: .regular)
            .tint(MailResourcesAsset.textSecondaryColor.swiftUIColor)
        }
    }
}

#Preview {
    AIDiscoveryPopover(isShowing: .constant(true))
}
