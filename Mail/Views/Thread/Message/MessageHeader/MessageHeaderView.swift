/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import RealmSwift
import SwiftUI

struct MessageHeaderView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.isMessageInteractive) private var isMessageInteractive

    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isHeaderExpanded = false

    @ObservedRealmObject var message: Message

    @Binding var isMessageExpanded: Bool

    var body: some View {
        VStack(spacing: IKPadding.medium) {
            MessageHeaderSummaryView(message: message,
                                     isMessageExpanded: $isMessageExpanded,
                                     isHeaderExpanded: $isHeaderExpanded,
                                     deleteDraftTapped: deleteDraft)

            if isHeaderExpanded {
                MessageHeaderDetailView(message: message)
                    .disabled(!isMessageInteractive)
            }
        }
        .contentShape(Rectangle())
        .padding(value: .medium)
        .onTapGesture {
            guard isMessageInteractive else { return }

            if message.isDraft {
                DraftUtils.editDraft(
                    from: message,
                    mailboxManager: mailboxManager,
                    composeMessageIntent: $mainViewState.composeMessageIntent
                )
            } else if message.originalThread?.messages.isEmpty == false {
                withAnimation {
                    isHeaderExpanded = false
                    isMessageExpanded.toggle()
                    matomo.track(eventWithCategory: .message, name: "openMessage", value: isMessageExpanded)
                }
            }
        }
    }

    private func deleteDraft() {
        matomo.track(eventWithCategory: .messageActions, name: "deleteDraft")
        Task {
            await tryOrDisplayError {
                try await mailboxManager.delete(draftMessages: [message])
            }
        }
    }
}

#Preview("Message collapsed") {
    MessageHeaderView(
        message: PreviewHelper.sampleMessage,
        isMessageExpanded: .constant(false)
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}

#Preview("Message expanded") {
    MessageHeaderView(
        message: PreviewHelper.sampleMessage,
        isMessageExpanded: .constant(true)
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}

#Preview("Message Header View") {
    MessageHeaderView(
        message: PreviewHelper.sampleMessage,
        isMessageExpanded: .constant(true)
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
