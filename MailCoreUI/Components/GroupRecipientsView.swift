/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import DesignSystem
import MailCore
import MailResources
import SwiftUI

struct GroupRecipientsView: View {
    let size: CGFloat

    private var iconSize: CGFloat {
        return size - 2 * IKPadding.mini
    }

    public init(size: CGFloat) {
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: size, height: size)
            .overlay {
                MailResourcesAsset.teamsUser.swiftUIImage
                    .resizable()
                    .foregroundStyle(MailResourcesAsset.backgroundColor)
                    .frame(width: iconSize, height: iconSize)
            }
    }
}

#Preview {
    GroupRecipientsView(size: 40)
}
