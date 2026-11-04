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

import Foundation
import MailCore

struct ThreadScheduledAbsenceAutoReplyCheckKey: Equatable {
    let summary: ScheduledAbsenceSummary?
    let loadedBodyMessageUids: [String]
}

@MainActor
final class ThreadScheduledAbsenceViewModel: ObservableObject {
    @Published private(set) var summary: ScheduledAbsenceSummary?
    @Published private(set) var descriptionsByEmail = [String: String]()

    private var recipients = [ScheduledAbsenceRecipient]()

    func displayName(for email: String) -> String {
        guard let name = recipients.first(where: { $0.email == email })?.name, !name.isEmpty else { return email }
        return name
    }

    func fetchAbsences(for recipients: [ScheduledAbsenceRecipient], mailboxManager: MailboxManager) async {
        if recipients != self.recipients {
            self.recipients = recipients
            summary = nil
            descriptionsByEmail = [:]
        }
        guard !recipients.isEmpty else { return }

        let emails = recipients.map(\.email)
        let absences = await mailboxManager.scheduledAbsenceProvider.absences(for: emails)
        guard !Task.isCancelled else { return }

        let now = Date()
        let summary = ScheduledAbsenceSummary(absencesByEmail: absences, orderedEmails: emails, now: now)
        self.summary = summary.mode == nil ? nil : summary
        descriptionsByEmail = ComposeScheduledAbsenceViewModel.chipDescriptions(absencesByEmail: absences, now: now)
    }

    /// Like the web, the "Absence message" action is hidden when a message of the thread already is the auto-reply.
    func hideActionIfAutoReplyIsDisplayed(in thread: Thread) async {
        guard let summary, !summary.isAutoReplyAlreadyDisplayed,
              let absence = summary.singleItem?.entry.absence,
              absence.displayableAutoReplyContent != nil else { return }

        let bodies = thread.messages.compactMap { ScheduledAbsenceMessageBody(body: $0.body) }
        let isAutoReplyDisplayed = await absence.isAutoReplyDisplayed(in: Array(bodies))
        guard isAutoReplyDisplayed, !Task.isCancelled, self.summary == summary else { return }

        self.summary?.isAutoReplyAlreadyDisplayed = true
    }
}
