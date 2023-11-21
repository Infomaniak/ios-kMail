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

struct IKButtonLabel: View {
    @Environment(\.controlSize) private var controlSize

    var title: String?
    var icon: MailResourcesImages?

    private var font: Font {
        if controlSize == .small {
            return MailTextStyle.bodySmall.font
        } else {
            return MailTextStyle.bodyMedium.font
        }
    }

    var body: some View {
        HStack(spacing: UIPadding.small) {
            if let icon {
                IKIcon(size: .medium, image: icon, shapeStyle: HierarchicalShapeStyle.primary)
            }

            if let title {
                Text(title)
                    .font(font)
            }
        }
    }
}

#Preview {
    VStack(spacing: UIPadding.medium) {
        IKButtonLabel(title: "Hello, World !", icon: MailResourcesAsset.pencilPlain)
            .controlSize(.small)
        IKButtonLabel(title: "Hello, World !", icon: MailResourcesAsset.pencilPlain)
        IKButtonLabel(icon: MailResourcesAsset.pencilPlain)
            .controlSize(.large)
    }
}
