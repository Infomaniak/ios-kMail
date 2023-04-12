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
import RealmSwift
import SwiftUI

struct SearchFilterCell: View {
    public var title: String
    public var isSelected: Bool

    var body: some View {
        HStack(spacing: 11) {
            if isSelected {
                MailResourcesAsset.check.swiftUIImage
                    .resizable()
                    .frame(width: 12, height: 12)
            }
            Text(title)
                .font(MailTextStyle.bodyMedium.font)
        }
        .filterCellStyle(isSelected: isSelected)
    }
}

struct SearchFilterCell_Previews: PreviewProvider {
    static var previews: some View {
        SearchFilterCell(title: "Lus", isSelected: true)
    }
}
