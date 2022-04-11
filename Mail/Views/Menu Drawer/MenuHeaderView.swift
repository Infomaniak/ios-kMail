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
import UIKit

struct MenuHeaderView: View {
    var splitViewController: UISplitViewController?

    var body: some View {
        HStack {
            Image("logo-mail")
                .resizable()
                .scaledToFit()
                .frame(height: 52)

            Spacer()

            Button {
                splitViewController?.setViewController(SettingsViewController(), for: .secondary)
            } label: {
                Image(uiImage: MailResourcesAsset.gear.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26)
            }
        }
        .padding([.leading, .trailing], MenuDrawerView.horizontalPadding)
        .padding([.top, .bottom])
        .background(Color(MailResourcesAsset.backgroundColor.color))
        .clipped()
        .shadow(color: Color(MailResourcesAsset.menuDrawerShadowColor.color), radius: 2, x: 0, y: 3)
    }
}

struct MenuHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        MenuHeaderView(splitViewController: UISplitViewController())
    }
}
