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

struct ThreadCellAnsweredView: View {
    let answered: Bool
    let forwarded: Bool

    private var image: Image? {
        if answered {
            return MailResourcesAsset.emailReplyFilled.swiftUIImage
        } else if forwarded {
            return MailResourcesAsset.emailForwardFilled.swiftUIImage
        }
        return nil
    }

    var body: some View {
        image?
            .resizable()
            .scaledToFit()
            .frame(width: 14)
            .foregroundStyle(MailResourcesAsset.textSecondaryColor)
            .padding(.trailing, UIPadding.verySmall)
    }
}

#Preview {
    VStack {
        ThreadCellAnsweredView(answered: true, forwarded: false)
        ThreadCellAnsweredView(answered: false, forwarded: true)
    }
}
