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

struct SearchFilterCell: View {
    @State public var title: String
    @State public var isSelected: Bool

    init(title: String, isSelected: Bool = false) {
        self.title = title
        self.isSelected = isSelected
    }

    var body: some View {
        HStack(spacing: 11) {
            if isSelected {
                Image(uiImage: MailResourcesAsset.check.image)
                    .resizable()
                    .frame(width: 13, height: 13)
            }
            Text(title)
                .font(MailTextStyle.body.font)
        }
        .padding([.top, .bottom], 6)
        .padding([.leading, .trailing], 11)
        .foregroundColor(isSelected ? Color.white : Color(uiColor: UserDefaults.shared.accentColor.primary.color))
        .background(isSelected ? Color(uiColor: UserDefaults.shared.accentColor.primary.color) : Color
            .white)
        .cornerRadius(40)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color(uiColor: UserDefaults.shared.accentColor.primary.color), lineWidth: 1)
        )
        .onTapGesture {
            isSelected.toggle()
        }
    }
}

struct SearchFilterCell_Previews: PreviewProvider {
    static var previews: some View {
        SearchFilterCell(title: "Lus")
        SearchFilterCell(title: "Lus", isSelected: true)
    }
}
