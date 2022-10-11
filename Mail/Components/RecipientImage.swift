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

struct RecipientImage: View {
    var recipient: Recipient
    var size: CGFloat

    @State private var image: Image?

    init(recipient: Recipient, size: CGFloat = 40) {
        self.image = recipient.cachedAvatarImage
        self.recipient = recipient
        self.size = size
    }

    var body: some View {
        if let image = image {
            ContactImage(image: image, size: size)
        } else {
            InitialsView(initials: recipient.initials, color: recipient.color, size: size)
                .task {
                    await fetchAvatar()
                }
        }
    }

    func fetchAvatar() async {
        if let avatarImage = await recipient.avatarImage {
            withAnimation {
                image = avatarImage
            }
        }
    }
}

struct RecipientImage_Previews: PreviewProvider {
    static var previews: some View {
        RecipientImage(recipient: PreviewHelper.sampleRecipient1)
    }
}
