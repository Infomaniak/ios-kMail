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

enum SelectionBackgroundKind {
    case none
    case multiple
    case folder
    case single

    var verticalPadding: CGFloat {
        switch self {
        case .multiple:
            return 2
        default:
            return 0
        }
    }

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

struct SelectionBackground: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    let selectionType: SelectionBackgroundKind
    var paddingLeading: CGFloat = 8
    var withAnimation = true

    var body: some View {
        Rectangle()
            .fill(selectionType == .single ? MailResourcesAsset.elementsColor.swiftUIColor : accentColor.secondary.swiftUIColor)
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .bottomLeft]))
            .padding(.leading, paddingLeading)
            .padding(.vertical, selectionType.verticalPadding)
            .opacity(selectionType.opacity)
            .animation(withAnimation ? .default : nil, value: selectionType.opacity)
    }
}

struct SelectionBackground_Previews: PreviewProvider {
    static var previews: some View {
        SelectionBackground(selectionType: SelectionBackgroundKind.single, paddingLeading: 10)
    }
}
