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
    let summary: ScheduledAbsenceSummary
    var showTopSeparator = true
    let showBottomSeparator: Bool
    /// Hides the "Absence message" action, e.g. when the read message already is the auto-reply.
    var isAutoReplyAlreadyDisplayed = false
    let displayName: (String) -> String

    private var actionTitle: String? {
        return isAutoReplyAlreadyDisplayed ? nil : summary.actionTitle
    }

    var body: some View {
        MessageHeaderActionView(
            icon: MailResourcesAsset.circleArrowRight.swiftUIImage,
            message: summary.bannerText(displayName: displayName),
            showTopSeparator: showTopSeparator,
            showBottomSeparator: showBottomSeparator,
            shouldDisplayActions: actionTitle != nil
        ) {
            if let actionTitle {
                if let absence = summary.singleItem?.entry.absence {
                    ScheduledAbsenceMessageButton(title: actionTitle, absence: absence)
                } else {
                    ScheduledAbsenceSeeDatesButton(title: actionTitle, summary: summary, displayName: displayName)
                }
            }
        }
    }
}

private struct ScheduledAbsenceMessageButton: View {
    @State private var isShowingScheduledAbsenceMessageView = false

    let title: String
    let absence: ScheduledAbsence

    private var panelTitle: String {
        return absence.displayableStatusText ?? MailResourcesStrings.Localizable.scheduledAbsenceMessageButton
    }

    var body: some View {
        Button(title) {
            isShowingScheduledAbsenceMessageView = true
        }
        .mailFloatingPanel(isPresented: $isShowingScheduledAbsenceMessageView, title: panelTitle) {
            ScheduledAbsenceMessageView(absence: absence)
        }
    }
}

private struct ScheduledAbsenceSeeDatesButton: View {
    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingScheduledAbsenceRecipientsView = false

    let title: String
    let summary: ScheduledAbsenceSummary
    let displayName: (String) -> String

    var body: some View {
        Button(title) {
            isShowingScheduledAbsenceRecipientsView = true
        }
        .mailFloatingPanel(isPresented: $isShowingScheduledAbsenceRecipientsView, title: summary.recipientsTitle) {
            ScheduledAbsenceRecipientsView(items: summary.items, displayName: displayName)
                .environmentObject(mailboxManager)
                .environment(\.currentUser, currentUser)
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
