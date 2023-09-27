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

struct AIPropositionMenu: View {
    var body: some View {
        Menu {
            Text("TODO: Display menu options")
        } label: {
            HStack(spacing: UIPadding.small) {
                MailResourcesAsset.pencil.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(MailResourcesStrings.Localizable.aiButtonAdjust)
            }
        }
        .tint(MailResourcesAsset.textSecondaryColor.swiftUIColor)
    }
}

struct AIMenu_Preview: PreviewProvider {
    static var previews: some View {
        AIPropositionMenu()
    }
}
