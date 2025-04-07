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
import MailResources
import RealmSwift
import SwiftUI

struct ThreadView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var displayNavigationTitle = false

    @ObservedRealmObject var thread: Thread

    private var externalTag: DisplayExternalRecipientStatus.State {
        thread.displayExternalRecipientState(
            mailboxManager: mailboxManager,
            recipientsList: thread.from
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: IKPadding.mini) {
                VStack(alignment: .leading, spacing: IKPadding.mini) {
                    Text(thread.formattedSubject)
                        .threadTitle()

                    ThreadTagsListView(externalTag: externalTag, searchFolderName: thread.searchFolderName)
                }
                .padding(.horizontal, value: .medium)

                if thread.isSnoozed, let snoozeEndDate = thread.snoozeEndDate {
                    SnoozedThreadHeaderView(date: snoozeEndDate, messages: thread.messages.toArray(), folder: thread.folder)
                }

                MessageListView(messages: thread.messages.toArray(), mailboxManager: mailboxManager)
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            displayNavigationTitle = offset < 0
        }
        .onAppear {
            matomo.trackThreadInfo(of: thread)
        }
        .task {
            await markThreadAsReadIfNeeded(thread: thread)
        }
        .navigationTitle(displayNavigationTitle ? thread.formattedSubject : "")
        .navigationBarThreadViewStyle(appearance: displayNavigationTitle ? BarAppearanceConstants
            .threadViewNavigationBarScrolledAppearance : BarAppearanceConstants.threadViewNavigationBarAppearance)
        .backButtonDisplayMode(.minimal)
        .threadViewToolbar(frozenThread: thread.freezeIfNeeded())
        .id(thread.id)
        .matomoView(view: [MatomoUtils.View.threadView.displayName, "Main"])
    }

    private func markThreadAsReadIfNeeded(thread: Thread) async {
        guard thread.hasUnseenMessages else { return }

        let originFolder = thread.folder?.freezeIfNeeded()
        try? await actionsManager.performAction(
            target: thread.messages.toArray(),
            action: .markAsRead,
            origin: .toolbar(originFolder: originFolder)
        )
    }
}

#Preview {
    ThreadView(thread: PreviewHelper.sampleThread)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
