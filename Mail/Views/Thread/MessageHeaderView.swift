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
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct MessageHeaderView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var navigationStore: NavigationStore
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var editedDraft: Draft?

    @ObservedRealmObject var message: Message

    @Binding var isHeaderExpanded: Bool
    @Binding var isMessageExpanded: Bool

    var body: some View {
        VStack(spacing: 12) {
            MessageHeaderSummaryView(message: message,
                                     isMessageExpanded: $isMessageExpanded,
                                     isHeaderExpanded: $isHeaderExpanded,
                                     deleteDraftTapped: deleteDraft)

            if isHeaderExpanded {
                MessageHeaderDetailView(message: message)
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
