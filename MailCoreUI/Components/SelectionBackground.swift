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

import MailCore
import MailResources
import SwiftUI

public enum SelectionBackgroundKind {
    case none
    case multiple
    case folder
    case single

    var opacity: Double {
        switch self {
        case .none:
            return 0
        default:
            return 1
        }
    }
}

struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

public struct SelectionBackground: View {
    let selectionType: SelectionBackgroundKind
    let paddingLeading: CGFloat
    let withAnimation: Bool
    let accentColor: AccentColor

    public init(
        selectionType: SelectionBackgroundKind,
        paddingLeading: CGFloat = IKPadding.small,
        withAnimation: Bool = true,
        accentColor: AccentColor
    ) {
        self.selectionType = selectionType
        self.paddingLeading = paddingLeading
        self.withAnimation = withAnimation
        self.accentColor = accentColor
    }

    public var body: some View {
        Rectangle()
            .fill(selectionType == .single ? MailResourcesAsset.elementsColor.swiftUIColor : accentColor.secondary.swiftUIColor)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .bottomLeft]))
            .padding(.leading, paddingLeading)
            .padding(.vertical, 2)
            .opacity(selectionType.opacity)
            .animation(withAnimation ? .default : nil, value: selectionType.opacity)
    }
}

#Preview {
    SelectionBackground(selectionType: SelectionBackgroundKind.single, paddingLeading: 8, accentColor: .blue)
}
