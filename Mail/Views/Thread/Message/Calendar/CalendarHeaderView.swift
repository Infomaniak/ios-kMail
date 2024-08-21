/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import MailCoreUI
import MailResources
import SwiftUI

struct CalendarHeaderView: View {
    let title: String

    var body: some View {
        HStack(spacing: IKPadding.small) {
            IKIcon(MailResourcesAsset.logoCalendar, size: .large)
            Text(title)
                .lineLimit(1)
                .textStyle(.bodyMedium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, value: .medium)
        .padding(.vertical, value: .small)
        .background(MailResourcesAsset.textFieldColor.swiftUIColor)
    }
}

#Preview {
    CalendarHeaderView(title: "Réunion Produit")
}
