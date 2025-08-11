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
import MailCore
import SwiftUI

struct ReactionCell: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    let emoji: String
    let author: UIReactionAuthor

    var body: some View {
        HStack(spacing: IKPadding.mini) {
            RecipientCell(
                recipient: author.recipient,
                bimi: author.bimi,
                avatarSize: 32,
                contextUser: currentUser.value,
                contextMailboxManager: mailboxManager
            )

            Text(emoji)
                .font(.system(size: 24))
        }
        .padding(.horizontal, value: .medium)
        .padding(.vertical, value: .mini)
    }
}

#Preview {
    ReactionCell(emoji: "🙂", author: UIReactionAuthor(recipient: PreviewHelper.sampleRecipient1, bimi: nil))
}
