/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftModalPresentation
import SwiftUI

struct MessageScheduleHeaderView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var mainViewState: MainViewState

    @State private var isShowingReschedulePanel = false

    let scheduleDate: Date
    let draftResource: String
    let showBottomSeparator: Bool

    var body: some View {
        MessageHeaderActionView(
            icon: MailResourcesAsset.clockPaperplane.swiftUIImage,
            message: MailResourcesStrings.Localizable.scheduledEmailHeader(DateFormatter.localizedString(
                from: scheduleDate,
                dateStyle: .full,
                timeStyle: .short
            )),
            showBottomSeparator: showBottomSeparator
        ) {
            HStack {
                Button(MailResourcesStrings.Localizable.buttonReschedule) {
                    isShowingReschedulePanel = true
                }

                MessageHeaderDivider()

                Button(MailResourcesStrings.Localizable.buttonModify) {
                    mainViewState.modifiedScheduleDraftResource = ModifiedScheduleDraftResource(draftResource: draftResource)
                }
            }
        }
        .scheduleFloatingPanel(
            isPresented: $isShowingReschedulePanel,
            type: .scheduledDraft,
            isUpdating: true,
            initialDate: scheduleDate,
            completionHandler: changeScheduleDate
        )
    }

    private func changeScheduleDate(_ selectedDate: Date?) {
        guard let selectedDate else { return }

        @InjectService var matomo: MatomoUtils
        matomo.track(
            eventWithCategory: .messageBanner,
            name: MessageBanner.schedule(scheduleDate: scheduleDate, draftResource: draftResource).matomoName
        )

        Task {
            await tryOrDisplayError {
                try await mailboxManager.apiFetcher.changeDraftSchedule(
                    draftResource: draftResource,
                    scheduleDate: selectedDate
                )
                try await mailboxManager.refreshAllSignatures()
                if let scheduleFolder = mailboxManager.getFolder(with: .scheduledDrafts) {
                    let freezedFolder = scheduleFolder.freezeIfNeeded()
                    await mailboxManager.refreshFolderContent(freezedFolder)
                }
            }
        }
    }
}
