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

@testable import MailCore
import Testing

@Suite("ScheduledAbsenceThreadRecipients")
struct ScheduledAbsenceThreadRecipientsTests {
    private static let mailboxEmail = "me@infomaniak.com"

    private func message(id: String, role: FolderRole?, isDraft: Bool = false, from: [String],
                         to: [String]) -> (Message, FolderRole?) {
        let message = Message()
        message.uid = id
        message.isDraft = isDraft
        message.from.append(objectsIn: from.map { Recipient(email: $0, name: "Name \($0)") })
        message.to.append(objectsIn: to.map { Recipient(email: $0, name: "") })
        return (message, role)
    }

    private func recipients(_ pairs: [(Message, FolderRole?)]) -> [String] {
        let roles = Dictionary(uniqueKeysWithValues: pairs.map { ($0.0.uid, $0.1) })
        return ScheduledAbsenceThreadRecipients.involvedRecipients(
            in: pairs.map(\.0),
            currentMailboxEmail: Self.mailboxEmail
        ) { roles[$0.uid] ?? nil }
            .map(\.email)
    }

    @Test func usesSenderForReceivedAndRecipientsForOutgoingMessages() {
        let result = recipients([
            message(id: "1", role: .inbox, from: ["Alice@Example.com"], to: [Self.mailboxEmail]),
            message(id: "2", role: .sent, from: [Self.mailboxEmail], to: ["bob@example.com", "alice@example.com"]),
            message(id: "3", role: .scheduledDrafts, from: [Self.mailboxEmail], to: ["carol@example.com"]),
            message(id: "4", role: nil, isDraft: true, from: [Self.mailboxEmail], to: ["dave@example.com"]),
            message(id: "5", role: .archive, from: ["ME@infomaniak.com"], to: ["eve@example.com"])
        ])

        #expect(result == [
            "alice@example.com",
            "bob@example.com",
            "carol@example.com",
            "dave@example.com",
            "eve@example.com"
        ])
    }

    @Test func prefersNonEmptyNameAndNormalizesEmails() {
        let pairs = [
            message(id: "1", role: .sent, from: [Self.mailboxEmail], to: ["Bob@Example.com"]),
            message(id: "2", role: .inbox, from: ["bob@example.com"], to: [Self.mailboxEmail])
        ]
        let roles = Dictionary(uniqueKeysWithValues: pairs.map { ($0.0.uid, $0.1) })

        let result = ScheduledAbsenceThreadRecipients.involvedRecipients(
            in: pairs.map(\.0),
            currentMailboxEmail: Self.mailboxEmail
        ) { roles[$0.uid] ?? nil }

        #expect(result == [ScheduledAbsenceRecipient(email: "bob@example.com", name: "Name bob@example.com")])
    }

    @Test func keepsNameAndLimitsResults() {
        let emails = (0 ..< 25).map { "user\($0)@example.com" }
        let pairs = emails.enumerated().map { message(id: "\($0.offset)", role: .inbox, from: [$0.element], to: []) }

        #expect(recipients(pairs) == Array(emails.prefix(ScheduledAbsenceProvider.maxEmails)))

        let first = ScheduledAbsenceThreadRecipients.involvedRecipients(
            in: [pairs[0].0],
            currentMailboxEmail: Self.mailboxEmail
        ) { _ in .inbox }.first
        #expect(first?.name == "Name user0@example.com")
    }
}
