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

import InfomaniakCore
import MailCore
import MailResources
import SwiftUI

struct MenuDrawerItemCell: View {
    let content: MenuItem

    var body: some View {
        Button(action: content.action) {
            HStack(spacing: 24) {
                Image(resource: content.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.accentColor)

                Text(content.label)
                    .textStyle(.header5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ItemCellView_Previews: PreviewProvider {
    static var previews: some View {
        MenuDrawerItemCell(content: MenuItem(icon: MailResourcesAsset.drawerDownload, label: "Importer des mails") { print("Hello") })
            .previewLayout(.sizeThatFits)
            .previewDevice(PreviewDevice(stringLiteral: "iPhone 11 Pro"))
    }
}
