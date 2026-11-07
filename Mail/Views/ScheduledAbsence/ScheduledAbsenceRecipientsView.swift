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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import SwiftUI

/// Lists the absent recipients with the dates of their absence.
struct ScheduledAbsenceRecipientsView: View {
    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager

    let items: [ScheduledAbsenceSummary.Item]
    let displayName: (String) -> String

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                let name = displayName(item.email)
                let isNameEmail = name.caseInsensitiveCompare(item.email) == .orderedSame
                RecipientCell(
                    contactConfiguration: .correspondent(
                        correspondent: Recipient(email: item.email, name: isNameEmail ? "" : name),
                        contextUser: currentUser.value,
                        contextMailboxManager: mailboxManager
                    ),
                    title: name,
                    subtitle: item.entry.occurrence.formattedRange
                )
                .accessibilityRemoveTraits(.isButton)
                .padding(.horizontal, value: .medium)
                .padding(.vertical, value: .small)
            }
        }
    }
}

#Preview {
    ScheduledAbsenceRecipientsView(items: PreviewHelper.sampleScheduledAbsenceMultipleSummary.items) { $0 }
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
