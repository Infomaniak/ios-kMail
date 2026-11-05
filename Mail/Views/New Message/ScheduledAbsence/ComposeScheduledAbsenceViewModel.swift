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
import SwiftUI

struct ComposeScheduledAbsenceRequest: Equatable {
    let recipients: [ScheduledAbsenceRecipient]
    let scheduleDate: Date?

    init(draft: Draft) {
        var seenEmails = Set<String>()
        recipients = Array(
            (Array(draft.to) + Array(draft.cc) + Array(draft.bcc))
                .map { ScheduledAbsenceRecipient(email: $0.email, name: $0.name) }
                .filter { !$0.email.isEmpty && seenEmails.insert($0.email).inserted }
                .prefix(ScheduledAbsenceProvider.maxEmails)
        )
        scheduleDate = draft.scheduleDate
    }
}

/// Fetches the scheduled absences of the draft recipients and computes what the composer should display.
@MainActor
final class ComposeScheduledAbsenceViewModel: ObservableObject {
    @Published private(set) var summary: ScheduledAbsenceSummary?
    @Published private(set) var chipDescriptionsByEmail = [String: String]()

    private let provider: ScheduledAbsenceProvider
    private let contactName: (String) -> String?
    private let debounceDuration: Duration
    private var recipientsByEmail = [String: ScheduledAbsenceRecipient]()
    private var absencesByEmail = [String: [ScheduledAbsenceEntry]]()
    private var lastNow = Date()

    init(
        provider: ScheduledAbsenceProvider,
        debounceDuration: Duration = .milliseconds(300),
        contactName: @escaping (String) -> String?
    ) {
        self.provider = provider
        self.debounceDuration = debounceDuration
        self.contactName = contactName
    }

    convenience init(mailboxManager: MailboxManager) {
        let contactManager = mailboxManager.contactManager
        self.init(provider: mailboxManager.scheduledAbsenceProvider) { email in
            contactManager.getContact(for: Recipient(email: email, name: ""))?.name
        }
    }

    /// Meant to be awaited from `.task(id:)` so that SwiftUI cancels it when the request changes or the view disappears.
    func update(_ request: ComposeScheduledAbsenceRequest) async {
        recipientsByEmail = Dictionary(uniqueKeysWithValues: request.recipients.map { ($0.email, $0) })

        let emails = request.recipients.map(\.email)
        let scheduleDate = request.scheduleDate

        // Removed recipients disappear right away, without waiting for the debounce and the fetch.
        let remainingAbsences = absencesByEmail.filter { recipientsByEmail[$0.key] != nil }
        apply(absencesByEmail: remainingAbsences, orderedEmails: emails, now: lastNow)

        guard !emails.isEmpty else { return }

        do {
            try await Task.sleep(for: debounceDuration)
        } catch {
            return
        }

        let absences: [String: [ScheduledAbsenceEntry]]
        if let scheduleDate {
            absences = await provider.absences(for: emails, at: scheduleDate)
        } else {
            absences = await provider.absences(for: emails)
        }

        guard !Task.isCancelled else { return }
        apply(absencesByEmail: absences, orderedEmails: emails, now: scheduleDate ?? Date())
    }

    /// Recipient name in the draft, else contact name, else email.
    func displayName(for email: String) -> String {
        if let name = recipientsByEmail[email]?.name, !name.isEmpty, name.caseInsensitiveCompare(email) != .orderedSame {
            return name
        }
        if let name = contactName(email), !name.isEmpty {
            return name
        }
        return email
    }

    private func apply(absencesByEmail: [String: [ScheduledAbsenceEntry]], orderedEmails: [String], now: Date) {
        self.absencesByEmail = absencesByEmail
        lastNow = now

        let newSummary = ScheduledAbsenceSummary(absencesByEmail: absencesByEmail, orderedEmails: orderedEmails, now: now)
        if newSummary != summary {
            summary = newSummary
        }

        let newDescriptions = ScheduledAbsenceSummary.descriptionsByEmail(absencesByEmail: absencesByEmail, now: now)
        if newDescriptions != chipDescriptionsByEmail {
            chipDescriptionsByEmail = newDescriptions
        }
    }
}
