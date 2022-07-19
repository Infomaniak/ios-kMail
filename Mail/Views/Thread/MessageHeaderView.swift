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
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct MessageHeaderView: View {
    @ObservedRealmObject var message: Message
    @Binding var isHeaderExpanded: Bool
    @Binding var isMessageExpanded: Bool

    @EnvironmentObject var mailboxManager: MailboxManager
    @EnvironmentObject var sheet: MessageSheet
    @EnvironmentObject var bottomSheet: MessageBottomSheet
    @EnvironmentObject var threadBottomSheet: ThreadBottomSheet

    var body: some View {
        VStack(spacing: 12) {
            MessageHeaderSummaryView(message: message,
                                     isMessageExpanded: $isMessageExpanded,
                                     isHeaderExpanded: $isHeaderExpanded,
                                     deleteDraftTapped: deleteDraft) {
                sheet.state = .reply(message, .reply)
            } moreButtonTapped: {
                threadBottomSheet.open(state: .actions(.message(message.thaw() ?? message)), position: .middle)
            }

            if isHeaderExpanded {
                MessageHeaderDetailView(message: message, recipientTapped: openContact(recipient:))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if message.isDraft {
                editDraft()
            } else {
                withAnimation {
                    isHeaderExpanded = false
                    isMessageExpanded.toggle()
                }
            }
        }
    }

    private func openContact(recipient: Recipient) {
        let isRemoteContact = AccountManager.instance.currentContactManager?.getContact(for: recipient.email)?.remote != nil
        bottomSheet.open(state: .contact(recipient, isRemote: isRemoteContact), position: isRemoteContact ? .remoteContactHeight : .defaultHeight)
    }

    private func editDraft() {
        var sheetPresented = false

        // If we already have the draft locally, present it directly
        if let draft = mailboxManager.draft(messageUid: message.uid)?.detached() {
            sheet.state = .edit(draft)
            sheetPresented = true
        }

        // Update the draft
        Task { [sheetPresented] in
            let draft = try await mailboxManager.draft(from: message)
            if !sheetPresented {
                sheet.state = .edit(draft)
            }
        }
    }

    private func deleteDraft() {
        Task {
            await tryOrDisplayError {
                try await mailboxManager.deleteDraft(from: message)
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
                isMessageExpanded: .constant(false)
            )
            MessageHeaderView(
                message: PreviewHelper.sampleMessage,
                isHeaderExpanded: .constant(false),
                isMessageExpanded: .constant(true)
            )
            MessageHeaderView(
                message: PreviewHelper.sampleMessage,
                isHeaderExpanded: .constant(true),
                isMessageExpanded: .constant(true)
            )
        }
        .previewLayout(.sizeThatFits)
    }
}
