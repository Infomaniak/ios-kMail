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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct MenuDrawerItemCell: View {
    let icon: MailResourcesImages
    let label: String
    let matomoName: String

    let action: () -> Void

    var body: some View {
        Button {
            @InjectService var matomo: MatomoUtils
            matomo.track(eventWithCategory: .menuDrawer, name: matomoName)
            action()
        } label: {
            HStack(spacing: IKPadding.menuDrawerCellSpacing) {
                icon
                    .iconSize(.large)

                Text(label)
                    .textStyle(.bodyMedium)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(IKPadding.menuDrawerCell)
        }
    }
}

#Preview {
    MenuDrawerItemCell(icon: MailResourcesAsset.drawerDownload, label: "Importer des mails", matomoName: "") { print("Hello") }
}
