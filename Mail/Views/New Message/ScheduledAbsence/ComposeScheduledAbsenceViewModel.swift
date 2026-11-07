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

extension EnvironmentValues {
    /// Description of the ongoing/upcoming absence of each recipient, keyed by lowercased email.
    @Entry
    var scheduledAbsenceDescriptions = [String: String]()
}

struct ComposeScheduledAbsenceRequest: Equatable {
    struct RecipientInfo: Equatable {
        let email: String
        let name: String
    }

    let recipients: [RecipientInfo]
    let scheduleDate: Date?

    init(draft: Draft) {
        let allRecipients = Array(draft.to) + Array(draft.cc) + Array(draft.bcc)
        var seenEmails = Set<String>()
        var recipients = [RecipientInfo]()
        for recipient in allRecipients {
            let email = recipient.email.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !email.isEmpty, seenEmails.insert(email.lowercased()).inserted else { continue }
            recipients.append(RecipientInfo(email: email, name: recipient.name))
            if recipients.count == ScheduledAbsenceProvider.maxEmails {
                break
            }
        }

        self.recipients = recipients
        scheduleDate = draft.scheduleDate
    }
}

/// Fetches the scheduled absences of the draft recipients and computes what the composer should display.
@MainActor
final class ComposeScheduledAbsenceViewModel: ObservableObject {
    static let debounceDuration: Duration = .milliseconds(300)

    @Published private(set) var absencesByEmail = [String: [ScheduledAbsenceEntry]]()
    @Published private(set) var summary = ScheduledAbsenceSummary(absencesByEmail: [:], orderedEmails: [], now: Date())
    @Published private(set) var chipDescriptionsByEmail = [String: String]()

    private let provider: ScheduledAbsenceProvider
    private let contactManager: ContactManageable
    private var recipientsByEmail = [String: ComposeScheduledAbsenceRequest.RecipientInfo]()
    private var fetchTask: Task<Void, Never>?

    init(mailboxManager: MailboxManager) {
        provider = mailboxManager.scheduledAbsenceProvider
        contactManager = mailboxManager.contactManager
    }

    func update(_ request: ComposeScheduledAbsenceRequest) {
        fetchTask?.cancel()

        recipientsByEmail = request.recipients.reduce(into: [:]) { result, recipient in
            result[recipient.email.lowercased()] = recipient
        }

        let emails = request.recipients.map(\.email)
        let scheduleDate = request.scheduleDate
        guard !emails.isEmpty else {
            apply(absencesByEmail: [:], orderedEmails: [], now: scheduleDate ?? Date())
            return
        }

        fetchTask = Task { [weak self, provider] in
            try? await Task.sleep(for: Self.debounceDuration)
            guard !Task.isCancelled else { return }

            let absences: [String: [ScheduledAbsenceEntry]]
            if let scheduleDate {
                let to = Calendar.current.date(byAdding: .day, value: ScheduledAbsenceProvider.lookAheadDays, to: scheduleDate)
                    ?? scheduleDate.addingTimeInterval(TimeInterval(ScheduledAbsenceProvider.lookAheadDays * 86400))
                absences = await provider.absences(for: emails, from: scheduleDate, to: to)
            } else {
                absences = await provider.absences(for: emails)
            }

            guard !Task.isCancelled else { return }
            self?.apply(absencesByEmail: absences, orderedEmails: emails, now: scheduleDate ?? Date())
        }
    }

    /// Recipient name in the draft, else contact name, else email.
    func displayName(for email: String) -> String {
        let recipient = recipientsByEmail[email.lowercased()]
        if let name = recipient?.name.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }

        let originalEmail = recipient?.email ?? email
        if let contactName = contactManager.getContact(for: Recipient(email: originalEmail, name: ""))?.name
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !contactName.isEmpty {
            return contactName
        }

        return originalEmail
    }

    private func apply(absencesByEmail: [String: [ScheduledAbsenceEntry]], orderedEmails: [String], now: Date) {
        let newSummary = ScheduledAbsenceSummary(absencesByEmail: absencesByEmail, orderedEmails: orderedEmails, now: now)
        self.absencesByEmail = absencesByEmail
        summary = newSummary
        chipDescriptionsByEmail = Self.chipDescriptions(absencesByEmail: absencesByEmail, now: now)
    }

    static func chipDescriptions(absencesByEmail: [String: [ScheduledAbsenceEntry]], now: Date) -> [String: String] {
        return absencesByEmail.reduce(into: [String: String]()) { result, element in
            let entries = element.value.sorted { $0.occurrence.start < $1.occurrence.start }
            guard let entry = entries.first(where: { $0.occurrence.isOngoing(at: now) })
                ?? entries.first(where: { $0.occurrence.isUpcoming(at: now) }) else { return }
            result[element.key.lowercased()] = entry.occurrence.chipDescription(now: now)
        }
    }
}
