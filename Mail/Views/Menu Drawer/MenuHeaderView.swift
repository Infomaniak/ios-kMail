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
import UIKit

struct MenuHeaderView: View {
    @EnvironmentObject var sheet: MenuSheet

    var body: some View {
        HStack {
            Image(resource: MailResourcesAsset.logoText)
                .resizable()
                .scaledToFit()
                .frame(height: 52)

            Spacer()

            Button {
                sheet.state = .settings
            } label: {
                Image(resource: MailResourcesAsset.cog)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 16)
        .padding(.leading, 18)
        .padding(.trailing, 14)
        .background(MailResourcesAsset.backgroundMenuDrawer.swiftUiColor)
        .clipped()
        .shadow(color: MailResourcesAsset.menuDrawerShadowColor.swiftUiColor, radius: 2, x: 0, y: 3)
    }
}

struct MenuHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        MenuHeaderView()
    }
}
