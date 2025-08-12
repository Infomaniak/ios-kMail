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

import InfomaniakCore
import InfomaniakDI
import MailCore
import MailCoreUI
import OrderedCollections
import RealmSwift
import SwiftUI

public extension UIReactionAuthor {
    init?(author: ReactionAuthor) {
        guard let recipient = author.recipient else { return nil }
        self.init(recipient: recipient, bimi: author.bimi)
    }

    init(user: InfomaniakCore.UserProfile) {
        let recipient = Recipient(email: user.email, name: user.displayName)
        self.init(recipient: recipient, bimi: nil)
    }
}

struct MessageReactionsView: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var reactions = [UIMessageReaction]()
    @State private var localReactions = OrderedSet<String>()

    let messageUid: String
    let messageReactions: RealmSwift.List<MessageReaction>

    var body: some View {
        ReactionsListView(reactions: reactions, addReaction: addReaction)
            .padding(.top, value: .small)
            .padding([.horizontal, .bottom], value: .medium)
            .task(id: messageReactions) {
                computeUIReactions()
            }
    }

    private func computeUIReactions() {
        var computedReactions = [UIMessageReaction]()
        var notHandledLocalReactions = localReactions
        for messageReaction in messageReactions {
            var authors = messageReaction.authors.compactMap { UIReactionAuthor(author: $0) }.toArray()
            var hasUserReacted = messageReaction.hasUserReacted

            if !hasUserReacted && localReactions.contains(messageReaction.reaction) {
                authors.append(UIReactionAuthor(user: currentUser.value))
                hasUserReacted = true
            }
            notHandledLocalReactions.remove(messageReaction.reaction)

            computedReactions.append(
                UIMessageReaction(reaction: messageReaction.reaction, authors: authors, hasUserReacted: hasUserReacted)
            )
        }

        for reaction in notHandledLocalReactions {
            computedReactions.append(
                UIMessageReaction(reaction: reaction, authors: [UIReactionAuthor(user: currentUser.value)], hasUserReacted: true)
            )
        }

        reactions = computedReactions
    }

    private func addReaction(_ reaction: String) {
        localReactions.append(reaction)
        computeUIReactions()

        Task {
            await createReactingDraft(reaction)

            @InjectService var draftManager: DraftManager
            draftManager.syncDraft(mailboxManager: mailboxManager, showSnackbar: true)

            // TODO: If it fails, remove from localReactions
        }
    }

    private func createReactingDraft(_ reaction: String) async {
        guard let liveMessage = mailboxManager.transactionExecutor.fetchObject(ofType: Message.self, forPrimaryKey: messageUid)
        else { return }

        let messageReply = MessageReply(frozenMessage: liveMessage.freezeIfNeeded(), replyMode: .reply)

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
    MessageReactionsView(messageUid: "", messageReactions: PreviewHelper.reactions)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
