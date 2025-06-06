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

import ElegantEmojiPicker
import MailCore
import MailCoreUI
import OrderedCollections
import RealmSwift
import SwiftUI

import InfomaniakDI

struct MessageReactionsView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var localReactions = OrderedSet<String>()
    @State private var selectedEmoji: Emoji?

    let message: Message

    var body: some View {
        ReactionsListView(
            selectedEmoji: $selectedEmoji,
            reactions: message.reactions.keys,
            reactionsCountForEmoji: reactionsCount,
            isReactionEnabled: isReactionEnabled,
            didTapReaction: didTapReaction,
            didLongPressReaction: didLongPressReaction
        )
        .padding(.top, value: .small)
        .padding([.horizontal, .bottom], value: .medium)
        .onAppear {
            localReactions.formUnion(message.reactions.keys)
        }
        .onChange(of: selectedEmoji) { newValue in
            guard let newValue else { return }
            didTapReaction(newValue.emoji)

            selectedEmoji = nil
        }
    }

    private func reactionsCount(for reaction: String) -> Int {
        var count = message.reactions[reaction]??.count ?? 0
        if localReactions.contains(reaction) && !hasCurrentUserRemotelyReacted(reaction) {
            count += 1
        }

        return count
    }

    private func isReactionEnabled(_ reaction: String) -> Bool {
        return localReactions.contains(reaction) || hasCurrentUserRemotelyReacted(reaction)
    }

    private func didTapReaction(_ reaction: String) {
        withAnimation {
            localReactions.append(reaction)
        }

        let draft = Draft.reacting(
            reaction: reaction,
            reply: MessageReply(frozenMessage: message.freezeIfNeeded(), replyMode: .reply),
            currentMailboxEmail: mailboxManager.mailbox.email
        )

        try? mailboxManager.writeTransaction { realm in
            realm.add(draft)
        }

        @InjectService var draftManager: DraftManager
        draftManager.syncDraft(mailboxManager: mailboxManager, showSnackbar: true)
    }

    private func didLongPressReaction(_ reaction: String) {
        // TODO: Handle in next PR
    }

    private func hasCurrentUserRemotelyReacted(_ reaction: String) -> Bool {
        return message.reactions[reaction]??.contains { $0.isMe(currentMailboxEmail: mailboxManager.mailbox.email) } ?? false
    }
}

#Preview {
    MessageReactionsView(message: PreviewHelper.sampleMessage)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
