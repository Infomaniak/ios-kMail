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
import InfomaniakDI
import MailCore
import MailCoreUI
import OrderedCollections
import RealmSwift
import SwiftUI

extension UIMessageReaction {
    init(messageReaction: MessageReaction, hasUserReacted: Bool) {
        self.init(
            reaction: messageReaction.reaction,
            recipients: messageReaction.recipients.toArray(),
            hasUserReacted: hasUserReacted
        )
    }
}

struct MessageReactionsView: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var reactions = [UIMessageReaction]()
    @State private var localReactions = OrderedSet<String>()

    let message: Message

    var body: some View {
        ReactionsListView(reactions: reactions, addReaction: addReaction)
            .padding(.top, value: .small)
            .padding([.horizontal, .bottom], value: .medium)
            .task(id: message.reactions) {
                reactions = message.reactions.map { reaction in
                    let hasReacted = reaction.recipients.contains { $0.isMe(currentMailboxEmail: mailboxManager.mailbox.email) }
                    return UIMessageReaction(messageReaction: reaction, hasUserReacted: hasReacted)
                }
            }
    }

    private func addReaction(_ reaction: String) {
        withAnimation {
            _ = localReactions.append(reaction)
        }

        Task {
            await createReactingDraft(reaction)

            @InjectService var draftManager: DraftManager
            draftManager.syncDraft(mailboxManager: mailboxManager, showSnackbar: true)
        }
    }

    private func createReactingDraft(_ reaction: String) async {
        let messageReply = MessageReply(frozenMessage: message.freezeIfNeeded(), replyMode: .reply)

        let draft = Draft.reacting(with: reaction, reply: messageReply, currentMailboxEmail: mailboxManager.mailbox.email)
        try? mailboxManager.writeTransaction { realm in
            realm.add(draft)
        }

        let draftContentManager = DraftContentManager(
            draftLocalUUID: draft.localUUID,
            messageReply: messageReply,
            mailboxManager: mailboxManager
        )
        _ = try? await draftContentManager.prepareCompleteDraft(incompleteDraft: draft.freezeIfNeeded())
    }
}

#Preview {
    MessageReactionsView(message: PreviewHelper.sampleMessage)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
