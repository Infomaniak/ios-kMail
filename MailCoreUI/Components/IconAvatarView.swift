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

import DesignSystem
import InfomaniakCoreSwiftUI
import MailResources
import SwiftUI

public struct IconAvatarView: View {
    public enum IconType {
        case unknownRecipient
        case groupRecipients
        case addressBook

        var icon: Image {
            switch self {
            case .unknownRecipient:
                MailResourcesAsset.userBold.swiftUIImage
            case .groupRecipients:
                MailResourcesAsset.teamsUser.swiftUIImage
            case .addressBook:
                MailResourcesAsset.bookUsers.swiftUIImage
            }
        }
    }

    let type: IconType
    let size: CGFloat

    private var iconSize: CGFloat {
        return size - 2 * IKPadding.mini
    }

    public init(type: IconType, size: CGFloat) {
        self.type = type
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: size, height: size)
            .overlay {
                type.icon
                    .resizable()
                    .foregroundStyle(MailResourcesAsset.backgroundColor)
                    .frame(width: iconSize, height: iconSize)
            }
    }
}

#Preview {
    HStack {
        IconAvatarView(type: .unknownRecipient, size: 40)
        IconAvatarView(type: .groupRecipients, size: 40)
    }
}
