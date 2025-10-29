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
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
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

extension MessageReactionsView {
    struct ReactionError: LocalizedError {
        let errorDescription: String

        init(errorDescription: String?) {
            self.errorDescription = errorDescription ?? MailResourcesStrings.Localizable.errorUnknown
        }
    }
}

struct MessageReactionsView: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    @LazyInjectService private var snackbarPresenter: IKSnackBarPresentable

    @State private var reactions = [UIReaction]()
    @State private var localReactions = OrderedSet<String>()
    @State private var userReactions = Set<String>()

    let messageUid: String
    let emojiReactionNotAllowedReason: EmojiReactionNotAllowedReason?
    let messageReactions: RealmSwift.List<MessageReaction>

    private var displayReactions: Bool {
        return !messageReactions.isEmpty || emojiReactionNotAllowedReason == nil
    }

    private var emojiPickerButtonIsDisabled: Bool {
        return emojiReactionNotAllowedReason != nil || userReactions.count >= 5
    }

    var body: some View {
        if displayReactions {
            ReactionsListView(
                reactions: reactions,
                emojiPickerButtonIsDisabled: emojiPickerButtonIsDisabled,
                addReaction: addReaction,
                disabledOpenEmojiPickerButtonCompletion: didTapDisabledEmojiPickerButton
            )
            .task(id: messageReactions) {
                computeUIReactions()
            }
        }
    }

    private func computeUIReactions() {
        var computedReactions = [UIReaction]()
        var notHandledLocalReactions = localReactions
        var computedUserReactions = Set<String>()

        for messageReaction in messageReactions {
            var authors = messageReaction.authors.compactMap { UIReactionAuthor(author: $0) }.toArray()
            var hasUserReacted = messageReaction.hasUserReacted

            if !hasUserReacted && localReactions.contains(messageReaction.reaction) {
                authors.append(UIReactionAuthor(user: currentUser.value))
                hasUserReacted = true
            }
            notHandledLocalReactions.remove(messageReaction.reaction)

            if hasUserReacted {
                computedUserReactions.insert(messageReaction.reaction)
            }
            computedReactions.append(
                UIReaction(reaction: messageReaction.reaction, authors: authors, hasUserReacted: hasUserReacted)
            )
        }

        for reaction in notHandledLocalReactions {
            computedReactions.append(
                UIReaction(reaction: reaction, authors: [UIReactionAuthor(user: currentUser.value)], hasUserReacted: true)
            )
            computedUserReactions.insert(reaction)
        }

        reactions = computedReactions
        userReactions = computedUserReactions
    }

    private func addReaction(_ reaction: String) {
        do {
            try ensureUserCanReact(reaction: reaction)
        } catch {
            snackbarPresenter.show(message: error.errorDescription)
            return
        }

        localReactions.append(reaction)
        computeUIReactions()

        Task {
            guard let draft = await createReactingDraft(reaction) else {
                cancelLocalReaction(reaction)
                return
            }

            do {
                @InjectService var draftManager: DraftManager
                try await draftManager.sendDraft(localUUID: draft.localUUID, mailboxManager: mailboxManager)
            } catch {
                cancelLocalReaction(reaction)
            }
        }
    }

    private func didTapDisabledEmojiPickerButton() {
        do {
            try ensureUserCanReact()
        } catch {
            snackbarPresenter.show(message: error.errorDescription)
        }
    }

    private func ensureUserCanReact(reaction: String? = nil) throws(ReactionError) {
        if let emojiReactionNotAllowedReason {
            throw ReactionError(errorDescription: emojiReactionNotAllowedReason.localizedDescription)
        }

        if let reaction, userReactions.contains(reaction) {
            throw ReactionError(errorDescription: MailApiError.emojiReactionAlreadyUsed.errorDescription)
        }

        if userReactions.count >= 5 {
            throw ReactionError(errorDescription: MailApiError.emojiReactionMaxReactionReached.errorDescription)
        }

        if ReachabilityListener.instance.currentStatus == .offline {
            throw ReactionError(errorDescription: MailResourcesStrings.Localizable.noConnection)
        }
    }

    private func createReactingDraft(_ reaction: String) async -> Draft? {
        guard let liveMessage = mailboxManager.transactionExecutor.fetchObject(ofType: Message.self, forPrimaryKey: messageUid)
        else { return nil }

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

        return draft
    }

    private func cancelLocalReaction(_ reaction: String) {
        localReactions.remove(reaction)
        computeUIReactions()
    }
}

#Preview {
    MessageReactionsView(messageUid: "", emojiReactionNotAllowedReason: nil, messageReactions: PreviewHelper.reactions)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
