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

struct CheckboxView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    let isSelected: Bool
    let size: CGFloat

    init(isSelected: Bool, density: ThreadDensity) {
        self.isSelected = isSelected
        size = density == .large ? UIConstants.checkboxLargeSize : UIConstants.checkboxSize
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.accentColor, lineWidth: isSelected ? 0 : 2)
                .background(Circle().fill(isSelected ? Color.accentColor : Color.clear))
                .frame(width: size, height: size)
            MailResourcesAsset.check.swiftUIImage
                .foregroundColor(accentColor.onAccent.swiftUIColor)
                .frame(height: UIConstants.checkmarkSize)
                .opacity(isSelected ? 1 : 0)
        }
        .animation(nil, value: isSelected)
    }
}

struct CheckboxView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CheckboxView(isSelected: false, density: .large)
            CheckboxView(isSelected: true, density: .large)
            CheckboxView(isSelected: false, density: .normal)
            CheckboxView(isSelected: true, density: .normal)
        }
    }
}
