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

import MailResources
import SwiftUI

struct ThreadCountIndicatorView: View {
    let messagesCount: Int
    let hasUnseenMessages: Bool

    var body: some View {
        Text("\(messagesCount)")
            .textStyle(hasUnseenMessages ? .labelMediumPrimary : .labelSecondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .lineLimit(1)
            .background(hasUnseenMessages ? .clear : MailResourcesAsset.unreadIndicatorBackgroundColor.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(hasUnseenMessages
                        ? MailResourcesAsset.textPrimaryColor.swiftUIColor
                        : MailResourcesAsset.elementsColor.swiftUIColor)
            }
    }
}

struct ThreadCountIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadCountIndicatorView(messagesCount: 2, hasUnseenMessages: false)
    }
}
