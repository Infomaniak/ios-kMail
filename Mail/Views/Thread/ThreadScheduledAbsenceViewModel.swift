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
    let summary: ScheduledAbsenceSummary
    let loadedBodiesCount: Int
}

@MainActor
final class ThreadScheduledAbsenceViewModel: ObservableObject {
    @Published private(set) var summary: ScheduledAbsenceSummary?
    /// Like the web, the "Absence message" action is hidden when a message of the thread already is the auto-reply.
    @Published private(set) var isAutoReplyAlreadyDisplayed = false
    @Published private(set) var descriptionsByEmail = [String: String]()

    private var threadUid: String?
    private var recipients = [ScheduledAbsenceRecipient]()
    /// Messages whose body was already compared with the auto-reply of the current `summary`.
    private var checkedMessageUids = Set<String>()

    func displayName(for email: String) -> String {
        guard let name = recipients.first(where: { $0.email == email })?.name, !name.isEmpty else { return email }
        return name
    }

    func fetchAbsences(threadUid: String, recipients: [ScheduledAbsenceRecipient], mailboxManager: MailboxManager) async {
        resetIfNeeded(threadUid: threadUid, recipients: recipients)
        guard !recipients.isEmpty else { return }

        let emails = recipients.map(\.email)
        let absences = await mailboxManager.scheduledAbsenceProvider.absences(for: emails)
        guard !Task.isCancelled else { return }

        update(absencesByEmail: absences, orderedEmails: emails, now: Date())
    }

    /// The view model outlives a thread when the split view detail switches to another one.
    func resetIfNeeded(threadUid: String, recipients: [ScheduledAbsenceRecipient]) {
        guard threadUid != self.threadUid || recipients != self.recipients else { return }

        self.threadUid = threadUid
        self.recipients = recipients
        summary = nil
        isAutoReplyAlreadyDisplayed = false
        descriptionsByEmail = [:]
        checkedMessageUids = []
    }

    func update(absencesByEmail: [String: [ScheduledAbsenceEntry]], orderedEmails: [String], now: Date) {
        let newSummary = ScheduledAbsenceSummary(absencesByEmail: absencesByEmail, orderedEmails: orderedEmails, now: now)
        if newSummary != summary {
            summary = newSummary
            isAutoReplyAlreadyDisplayed = false
            checkedMessageUids = []
        }

        let newDescriptions = ScheduledAbsenceSummary.descriptionsByEmail(absencesByEmail: absencesByEmail, now: now)
        if newDescriptions != descriptionsByEmail {
            descriptionsByEmail = newDescriptions
        }
    }

    /// Only the loaded bodies that were not compared yet are checked.
    func hideActionIfAutoReplyIsDisplayed(in messages: [Message]) async {
        guard let summary, !isAutoReplyAlreadyDisplayed,
              let absence = summary.singleItem?.entry.absence,
              absence.displayableAutoReplyContent != nil else { return }

        let uncheckedMessages = messages.filter { $0.body != nil && !checkedMessageUids.contains($0.uid) }
        guard !uncheckedMessages.isEmpty else { return }

        let bodies = uncheckedMessages.compactMap { ScheduledAbsenceMessageBody(body: $0.body) }
        let uncheckedUids = uncheckedMessages.map(\.uid)
        let isAutoReplyDisplayed = await absence.isAutoReplyDisplayed(in: bodies)
        guard !Task.isCancelled, self.summary == summary else { return }

        checkedMessageUids.formUnion(uncheckedUids)
        if isAutoReplyDisplayed {
            isAutoReplyAlreadyDisplayed = true
        }
    }
}
