/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

public enum ThreadCellChipItem: String {
    case tag

    var contentDescription: String {
        switch self {
        case .tag:
            return MailResourcesStrings.Localizable.contentDescriptionIconMention
        }
    }

    public var icon: Image {
        switch self {
        case .tag:
            return MailResourcesAsset.mentionTag.swiftUIImage
        }
    }
}

struct ThreadCellChip: View {
    let chipItem: ThreadCellChipItem
    var body: some View {
        ZStack {
            UserDefaults.shared.accentColor.secondary.swiftUIColor
            chipItem.icon
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(UserDefaults.shared.accentColor.primary)
                .accessibilityLabel(chipItem.contentDescription)
                .padding(1)
        }
        .cornerRadius(IKRadius.small)
        .frame(width: IKIconSize.medium.rawValue, height: IKIconSize.medium.rawValue)
    }
}

#Preview {
    ThreadCellChip(chipItem: .tag)
}
