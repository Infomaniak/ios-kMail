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
import MailCoreUI
import RealmSwift
import SwiftUI

struct MessageReactionsView: View {
    let reactions: Map<String, MailCore.RecipientsList?>

    var body: some View {
        ReactionsListView(
            reactions: reactions.keys,
            reactionsCountForEmoji: reactionsCount,
            isReactionEnabled: isReactionEnabled,
            didTapButton: didTapReaction,
            didLongPressButton: didLongPressReaction
        )
        .padding(.top, value: .small)
        .padding([.horizontal, .bottom], value: .medium)
    }

    private func reactionsCount(for emoji: String) -> Int {
        return reactions[emoji]??.recipients.count ?? 0
    }

    private func isReactionEnabled(_ emoji: String) -> Bool {
        return false
    }

    private func didTapReaction(_ reaction: String) {

    }

    private func didLongPressReaction(_ reaction: String) {

    }
}

#Preview {
    MessageReactionsView(reactions: Map())
}
