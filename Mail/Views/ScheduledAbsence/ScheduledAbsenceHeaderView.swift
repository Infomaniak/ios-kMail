/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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

import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ScheduledAbsenceHeaderView: View {
    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var displayedAbsenceEntry: ScheduledAbsenceEntry?
    @State private var isShowingScheduledAbsenceRecipientsView = false

    let summary: ScheduledAbsenceSummary
    let showTopSeparator: Bool
    let showBottomSeparator: Bool

    var body: some View {
        MessageHeaderActionView(
            icon: MailResourcesAsset.circleArrowRight.swiftUIImage,
            message: summary.bannerText,
            showTopSeparator: showTopSeparator,
            showBottomSeparator: showBottomSeparator,
            shouldDisplayActions: summary.actionTitle != nil
        ) {
            if let actionTitle = summary.actionTitle {
                Button(actionTitle, action: showAbsenceDetails)
            }
        }
        .mailFloatingPanel(
            item: $displayedAbsenceEntry,
            title: MailResourcesStrings.Localizable.scheduledAbsenceMessageButton
        ) { entry in
            ScheduledAbsenceMessageView(absence: entry.absence)
        }
        .mailFloatingPanel(isPresented: $isShowingScheduledAbsenceRecipientsView, title: summary.recipientsTitle) {
            ScheduledAbsenceRecipientsView(absentRecipients: summary.absentRecipients, now: summary.now)
                .environmentObject(mailboxManager)
                .environment(\.currentUser, currentUser)
        }
    }

    private func showAbsenceDetails() {
        if let entry = summary.singleAbsentRecipient?.entry {
            displayedAbsenceEntry = entry
        } else {
            isShowingScheduledAbsenceRecipientsView = true
        }
    }
}

#Preview {
    ScheduledAbsenceHeaderView(
        summary: PreviewHelper.sampleScheduledAbsenceSingleSummary,
        showTopSeparator: true,
        showBottomSeparator: true
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
