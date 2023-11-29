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

struct ChevronIcon: View {
    enum Style {
        case up, right, left, down

        var rotationAngle: Angle {
            switch self {
            case .up:
                return .zero
            case .right:
                return .radians(.pi / 2)
            case .down:
                return .radians(.pi)
            case .left:
                return .radians(3 * .pi / 2)
            }
        }
    }

    let style: Style
    var color: any ShapeStyle = MailResourcesAsset.textSecondaryColor.swiftUIColor

    var body: some View {
        IKIcon(MailResourcesAsset.chevronUp, size: .small)
            .rotationEffect(style.rotationAngle)
            .foregroundStyle(AnyShapeStyle(color))
    }
}

struct ChevronButton: View {
    @Binding var isExpanded: Bool

    var color = MailResourcesAsset.textSecondaryColor.swiftUIColor

    var body: some View {
        Button {
            withAnimation {
                isExpanded.toggle()
            }
        } label: {
            ChevronIcon(style: isExpanded ? .up : .down, color: color)
        }
    }
}

struct ChevronIcon_Previews: PreviewProvider {
    static var previews: some View {
        ChevronIcon(style: .up)
        ChevronIcon(style: .down)
    }
}
