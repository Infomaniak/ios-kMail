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
                MailResourcesAsset.user.swiftUIImage
            case .groupRecipients:
                MailResourcesAsset.teamsUser.swiftUIImage
            case .addressBook:
                MailResourcesAsset.bookUser.swiftUIImage
            }
        }
    }

    let type: IconType

    public init(type: IconType) {
        self.type = type
    }

    public var body: some View {
        Circle()
            .fill(.tint)
            .overlay {
                type.icon
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(MailResourcesAsset.backgroundColor)
                    .padding(value: .mini)
            }
    }
}

#Preview {
    HStack {
        IconAvatarView(type: .unknownRecipient)
            .frame(width: 40, height: 40)
        IconAvatarView(type: .groupRecipients)
            .frame(width: 40, height: 40)
    }
}
