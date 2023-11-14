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

struct IKIcon: View {
    enum Size {
        case small, medium, large

        var heightAndWidth: CGFloat {
            switch self {
            case .small:
                return 12
            case .medium:
                return 16
            case .large:
                return 24
            }
        }
    }

    let size: Size
    var image: MailResourcesImages
    var color = UserDefaults.shared.accentColor.primary.swiftUIColor

    var body: some View {
        image.swiftUIImage
            .resizable()
            .scaledToFit()
            .frame(width: size.heightAndWidth, height: size.heightAndWidth)
            .foregroundStyle(color)
    }
}

#Preview {
    IKIcon(size: .large, image: MailResourcesAsset.folder)
}
