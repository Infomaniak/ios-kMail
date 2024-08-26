/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import MailCore
import MailResources
import SwiftUI

extension ThreadDensity {
    var checkboxSize: CGFloat {
        switch self {
        case .compact, .normal:
            return 32
        case .large:
            return 40
        }
    }
}

public struct CheckboxView: View {
    let accentColor: AccentColor
    let isSelected: Bool
    let size: CGFloat

    public init(isSelected: Bool, density: ThreadDensity, accentColor: AccentColor) {
        self.isSelected = isSelected
        self.accentColor = accentColor
        size = density.checkboxSize
    }

    public var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.accentColor, lineWidth: isSelected ? 0 : 2)
                .background(Circle().fill(isSelected ? Color.accentColor : Color.clear))
                .frame(width: size, height: size)
            MailResourcesAsset.check.swiftUIImage
                .foregroundStyle(accentColor.onAccent)
                .frame(height: 16)
                .opacity(isSelected ? 1 : 0)
        }
        .animation(nil, value: isSelected)
    }
}

#Preview {
    VStack {
        CheckboxView(isSelected: false, density: .large, accentColor: .blue)
        CheckboxView(isSelected: true, density: .large, accentColor: .blue)
        CheckboxView(isSelected: false, density: .normal, accentColor: .blue)
        CheckboxView(isSelected: true, density: .normal, accentColor: .blue)
    }
}
