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

import InfomaniakCore
import InfomaniakCoreUI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct MessageHeaderView: View {
    @State private var editedDraft: Draft?
    @State var messageReply: MessageReply?
    @ObservedRealmObject var message: Message
    @Binding var isHeaderExpanded: Bool
    @Binding var isMessageExpanded: Bool

    @EnvironmentObject var mailboxManager: MailboxManager
    @EnvironmentObject var bottomSheet: MessageBottomSheet
    @EnvironmentObject var threadBottomSheet: ThreadBottomSheet

    let matomo: MatomoUtils

    var body: some View {
        VStack(spacing: 12) {
            MessageHeaderSummaryView(message: message,
                                     isMessageExpanded: $isMessageExpanded,
                                     isHeaderExpanded: $isHeaderExpanded,
                                     matomo: matomo,
                                     deleteDraftTapped: deleteDraft) {
                matomo.track(eventWithCategory: .messageActions, name: "reply")
                if message.canReplyAll {
                    bottomSheet.open(state: .replyOption(message, isThread: false))
                } else {
                    messageReply = MessageReply(message: message, replyMode: .reply)
                }
            } moreButtonTapped: {
                threadBottomSheet.open(state: .actions(.message(message.thaw() ?? message)))
            } recipientTapped: { recipient in
                openContact(recipient: recipient)
            }

            if isHeaderExpanded {
                MessageHeaderDetailView(message: message, recipientTapped: openContact(recipient:))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if message.isDraft {
                DraftUtils.editDraft(from: message, mailboxManager: mailboxManager, editedMessageDraft: $editedDraft)
            } else if message.originalThread?.messagesCount ?? 0 > 1 {
                withAnimation {
                    isHeaderExpanded = false
                    isMessageExpanded.toggle()
                    matomo.track(eventWithCategory: .message, name: "openMessage", value: isMessageExpanded)
                }
            }
        }
        .sheet(item: $editedDraft) { editedDraft in
            ComposeMessageView.editDraft(draft: editedDraft, mailboxManager: mailboxManager)
        }
        .sheet(item: $messageReply) { messageReply in
            ComposeMessageView.replyOrForwardMessage(messageReply: messageReply, mailboxManager: mailboxManager)
        }
    }

    private func openContact(recipient: Recipient) {
        let isRemoteContact = AccountManager.instance.currentContactManager?.getContact(for: recipient)?.remote != nil
        bottomSheet.open(
            state: .contact(recipient, isRemote: isRemoteContact)
        )
    }

    private func deleteDraft() {
        matomo.track(eventWithCategory: .messageActions, name: "deleteDraft")
        Task {
            await tryOrDisplayError {
                try await mailboxManager.delete(draftMessage: message)
            }
        }
    }
}

struct MessageHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageHeaderView(
                message: PreviewHelper.sampleMessage,
                isHeaderExpanded: .constant(false),
                isMessageExpanded: .constant(false),
                matomo: PreviewHelper.sampleMatomo
            )
            MessageHeaderView(
                message: PreviewHelper.sampleMessage,
                isHeaderExpanded: .constant(false),
                isMessageExpanded: .constant(true),
                matomo: PreviewHelper.sampleMatomo
            )
            MessageHeaderView(
                message: PreviewHelper.sampleMessage,
                isHeaderExpanded: .constant(true),
                isMessageExpanded: .constant(true),
                matomo: PreviewHelper.sampleMatomo
            )
        }
        .previewLayout(.sizeThatFits)
    }
}
