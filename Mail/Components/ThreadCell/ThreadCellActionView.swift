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

import MailCore
import MailResources
import SwiftUI

struct ThreadCellActionView: View {
    let lastAction: ThreadLastAction?

    private var image: Image? {
        switch lastAction {
        case .forward:
            return MailResourcesAsset.emailForwardFilled.swiftUIImage
        case .reply:
            return MailResourcesAsset.emailReplyFilled.swiftUIImage
        case nil:
            return nil
        }
    }

    private var accessibilityLabel: String {
        switch lastAction {
        case .forward:
            return MailResourcesStrings.Localizable.contentDescriptionIconForward
        case .reply:
            return MailResourcesStrings.Localizable.contentDescriptionIconReply
        case nil:
            return ""
        }
    }

    var body: some View {
        image?
            .resizable()
            .scaledToFit()
            .frame(width: 16)
            .foregroundStyle(MailResourcesAsset.textSecondaryColor)
            .padding(.trailing, value: .micro)
            .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    VStack {
        ThreadCellActionView(lastAction: .forward)
        ThreadCellActionView(lastAction: .reply)
    }
}
