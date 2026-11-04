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

/// Informs about the scheduled absences of the thread correspondents or of the draft recipients.
///
/// Absence texts come from other users: they are only displayed as plain `Text`.
struct ScheduledAbsenceHeaderView: View {
    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingMessageView = false
    @State private var isShowingRecipientsView = false

    let summary: ScheduledAbsenceSummary
    var showTopSeparator = true
    let showBottomSeparator: Bool
    let displayName: (String) -> String

    private var messageTitle: String {
        guard let statusText = summary.singleItem?.entry.absence.statusText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !statusText.isEmpty else {
            return MailResourcesStrings.Localizable.scheduledAbsenceMessageButton
        }
        return statusText
    }

    var body: some View {
        if let bannerText = summary.bannerText(displayName: summary.singleItem.map { displayName($0.email) }) {
            MessageHeaderActionView(
                icon: MailResourcesAsset.circleArrowRight.swiftUIImage,
                message: bannerText,
                showTopSeparator: showTopSeparator,
                showBottomSeparator: showBottomSeparator,
                shouldDisplayActions: summary.actionTitle != nil
            ) {
                if let actionTitle = summary.actionTitle {
                    Button(actionTitle) {
                        if summary.singleItem != nil {
                            isShowingMessageView = true
                        } else {
                            isShowingRecipientsView = true
                        }
                    }
                    .mailFloatingPanel(
                        isPresented: $isShowingMessageView,
                        title: messageTitle
                    ) {
                        if let absence = summary.singleItem?.entry.absence {
                            ScheduledAbsenceMessageView(absence: absence)
                        }
                    }
                    .mailFloatingPanel(isPresented: $isShowingRecipientsView, title: summary.recipientsTitle) {
                        ScheduledAbsenceRecipientsView(items: summary.displayedEntries, displayName: displayName)
                            .environmentObject(mailboxManager)
                            .environment(\.currentUser, currentUser)
                    }
                }
            }
        }
    }
}

#Preview {
    ScheduledAbsenceHeaderView(
        summary: PreviewHelper.sampleScheduledAbsenceSingleSummary,
        showBottomSeparator: true
    ) { _ in "Laura Snow" }
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
