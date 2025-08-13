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

import MailCore
import SwiftUI

struct ReactionsList: View {
    let reactions: [UIReaction]

    init(reactions: [UIReaction]) {
        self.reactions = reactions
    }

    init(reaction: UIReaction) {
        self.init(reactions: [reaction])
    }

    var body: some View {
        ScrollView {
            VStack {
                ForEach(reactions) { reaction in
                    ForEach(reaction.authors) { author in
                        ReactionCell(emoji: reaction.emoji, author: author)
                    }
                }
            }
            .padding(.vertical, value: .mini)
        }
    }
}

#Preview {
    ReactionsList(reactions: PreviewHelper.uiReactions)
}
