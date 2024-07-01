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

import MailResources
import SwiftUI

public struct ChevronIcon<ChevronShapeStyle: ShapeStyle>: View {
    public enum Direction {
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

    let direction: Direction
    let shapeStyle: ChevronShapeStyle

    public init(direction: Direction, shapeStyle: ChevronShapeStyle = MailResourcesAsset.textSecondaryColor.swiftUIColor) {
        self.direction = direction
        self.shapeStyle = shapeStyle
    }

    public var body: some View {
        IKIcon(MailResourcesAsset.chevronUp, size: .small)
            .rotationEffect(direction.rotationAngle)
            .foregroundStyle(shapeStyle)
    }
}

public struct ChevronButton: View {
    @Binding var isExpanded: Bool

    let color: Color

    public init(isExpanded: Binding<Bool>, color: Color = MailResourcesAsset.textSecondaryColor.swiftUIColor) {
        _isExpanded = isExpanded
        self.color = color
    }

    public var body: some View {
        Button {
            withAnimation {
                isExpanded.toggle()
            }
        } label: {
            ChevronIcon(direction: isExpanded ? .up : .down, shapeStyle: color)
                .padding(value: .regular)
        }
    }
}

#Preview {
    ChevronIcon(direction: .up)
}

#Preview {
    ChevronIcon(direction: .down)
}
