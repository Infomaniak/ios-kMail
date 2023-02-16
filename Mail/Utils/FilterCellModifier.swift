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

struct FilterCellModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 6)
            .padding(.horizontal, 11)
            .foregroundColor(isSelected ? UserDefaults.shared.accentColor.onAccent.swiftUiColor : .accentColor)
            .background(isSelected ? .accentColor : MailResourcesAsset.backgroundColor.swiftUiColor)
            .cornerRadius(40)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.accentColor, lineWidth: 1)
            )
    }
}

extension View {
    func filterCellStyle(isSelected: Bool) -> some View {
        modifier(FilterCellModifier(isSelected: isSelected))
    }
}
