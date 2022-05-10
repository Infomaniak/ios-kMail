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
import MailCore

struct MenuItem: Identifiable {
    let id = UUID()

    var icon: MailResourcesImages
    var label: String

    var action: () -> Void
}

struct MenuDrawerItemsListView: View {
    var title: String?
    var content: [MenuItem]

    var body: some View {
        VStack(alignment: .leading) {
            if let title = title {
                Text(title)
                    .textStyle(.calloutSecondary)
                    .padding(.bottom, 6)
            }

            ForEach(content) { item in
                MenuDrawerItemCell(content: item)
            }
        }
    }
}

struct ItemsListView_Previews: PreviewProvider {
    static var previews: some View {
        MenuDrawerItemsListView(title: "Actions avancées",
                      content: [
                        MenuItem(icon: MailResourcesAsset.drawerArrow, label: "Importer des mails") { print("Hello") },
                        MenuItem(icon: MailResourcesAsset.synchronizeArrow, label: "Restaurer des mails") { print("Hello") }
                      ])
        .previewLayout(.sizeThatFits)
        .previewDevice(PreviewDevice(stringLiteral: "iPhone 11 Pro"))
    }
}
