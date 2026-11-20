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
import InfomaniakCore
@testable import MailCore
import Testing

enum ScheduledAbsenceFixtures {
    private static let dateFormatter = ISO8601DateFormatter()

    static func date(_ string: String) -> Date {
        return dateFormatter.date(from: string)!
    }

    static func entry(
        uuid: String = UUID().uuidString,
        start: String,
        end: String,
        fullday: Bool = false,
        autoReplyContent: String? = nil
    ) -> ScheduledAbsenceEntry {
        return ScheduledAbsenceEntry(
            absence: ScheduledAbsence(uuid: uuid, autoReplyContent: autoReplyContent),
            occurrence: ScheduledAbsenceOccurrence(start: date(start), end: date(end), fullday: fullday)
        )
    }
}

@Suite("ScheduledAbsenceDecoding")
struct ScheduledAbsenceDecodingTests {
    private let json = """
    {
        "alice@example.com": [
            {
                "absence": {
                    "uuid": "a1",
                    "status_emoji": "palm_tree",
                    "status_text": "En vacances",
                    "auto_reply_content": "Back soon",
                    "disable_kchat_notification": true,
                    "auto_decline_invitation": false,
                    "created_at": "2026-04-01T10:00:00+02:00",
                    "updated_at": null
                },
                "occurrence": { "start": "2026-05-04T00:00:00+00:00", "end": "2026-05-09T00:00:00+00:00", "fullday": true }
            }
        ],
        "bob@example.com": null,
        "carol@example.com": [
            {
                "absence": { "uuid": "c1" },
                "occurrence": { "start": "2026-09-29T10:00:00+02:00", "end": "2026-09-30T18:00:00+02:00", "fullday": false }
            }
        ]
    }
    """

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    @Test func decodesResponseWithNullEntries() throws {
        let absences = try decoder.decode([String: [ScheduledAbsenceEntry]?].self, from: Data(json.utf8))

        #expect(absences["bob@example.com"] == .some(nil))

        let alice = try #require(absences["alice@example.com"] ?? nil)
        #expect(alice.count == 1)
        #expect(alice[0].absence.statusText == "En vacances")
        #expect(alice[0].occurrence.fullday)
        #expect(alice[0].occurrence.end == ScheduledAbsenceFixtures.date("2026-05-09T00:00:00Z"))

        let carol = try #require((absences["carol@example.com"] ?? nil)?.first)
        #expect(carol.absence.statusText == nil)
        #expect(carol.absence.autoReplyContent == nil)
        #expect(!carol.occurrence.fullday)
        #expect(carol.occurrence.start == ScheduledAbsenceFixtures.date("2026-09-29T08:00:00Z"))
    }
}

@Suite("ScheduledAbsenceOccurrence")
struct ScheduledAbsenceOccurrenceTests {
    private let zurich = TimeZone(identifier: "Europe/Zurich")!
    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    private let fulldayOccurrence = ScheduledAbsenceFixtures.entry(
        start: "2026-05-04T00:00:00Z",
        end: "2026-05-09T00:00:00Z",
        fullday: true
    ).occurrence

    private let timedOccurrence = ScheduledAbsenceFixtures.entry(
        start: "2026-09-29T10:00:00+02:00",
        end: "2026-09-30T18:00:00+02:00"
    ).occurrence

    @Test func fulldayOccurrenceComparesLocalCalendarDays() {
        let dayBeforeLate = ScheduledAbsenceFixtures.date("2026-05-03T23:30:00+02:00")
        #expect(fulldayOccurrence.state(at: dayBeforeLate, timeZone: zurich) == .upcoming)

        let firstDayEarly = ScheduledAbsenceFixtures.date("2026-05-04T00:30:00+02:00")
        #expect(fulldayOccurrence.state(at: firstDayEarly, timeZone: zurich) == .ongoing)

        let lastDayLate = ScheduledAbsenceFixtures.date("2026-05-08T23:30:00-07:00")
        #expect(fulldayOccurrence.state(at: lastDayLate, timeZone: losAngeles) == .ongoing)

        let firstDayBack = ScheduledAbsenceFixtures.date("2026-05-09T00:30:00+02:00")
        #expect(fulldayOccurrence.state(at: firstDayBack, timeZone: zurich) == .past)
    }

    @Test func timedOccurrenceHasExclusiveEnd() {
        let before = ScheduledAbsenceFixtures.date("2026-09-29T09:59:59+02:00")
        #expect(timedOccurrence.state(at: before, timeZone: zurich) == .upcoming)
        #expect(timedOccurrence.state(at: timedOccurrence.start, timeZone: losAngeles) == .ongoing)
        #expect(timedOccurrence.state(at: timedOccurrence.end, timeZone: losAngeles) == .past)
    }
}

@Suite("ScheduledAbsence")
struct ScheduledAbsenceTests {
    @Test(arguments: [
        (" \n Back soon \n", "Back soon"),
        (" \n\t", nil),
        (nil, nil)
    ] as [(String?, String?)])
    func displayableAutoReplyContent(content: String?, expected: String?) {
        #expect(ScheduledAbsence(uuid: "a1", autoReplyContent: content).displayableAutoReplyContent == expected)
    }
}

@Suite("ScheduledAbsenceEndpoint")
struct ScheduledAbsenceEndpointTests {
    @Test func endpointDeduplicatesEmailsCaseInsensitively() throws {
        let endpoint = Endpoint.activeScheduledAbsences(
            emails: ["Alice@Example.com", "alice@example.com", "bob@example.com"],
            from: Date(),
            to: Date()
        )
        let components = try #require(URLComponents(url: endpoint.url, resolvingAgainstBaseURL: false))
        let attendees = components.queryItems?.filter { $0.name == "attendees[]" }.map(\.value)

        #expect(attendees == ["alice@example.com", "bob@example.com"])
    }
}

@Suite("ScheduledAbsenceFormatting")
struct ScheduledAbsenceFormattingTests {
    @Test func fulldayEndsTheDayBeforeInUTC() {
        let occurrence = ScheduledAbsenceFixtures.entry(
            start: "2026-05-04T00:00:00+00:00",
            end: "2026-05-09T00:00:00+00:00",
            fullday: true
        ).occurrence

        #expect(occurrence.lastDisplayedDate == occurrence.end.addingTimeInterval(-1))
    }

    @Test func nonFulldayKeepsEnd() throws {
        let start = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 4, hour: 12)))
        let end = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 8, hour: 12)))
        let occurrence = ScheduledAbsenceOccurrence(start: start, end: end, fullday: false)

        #expect(occurrence.lastDisplayedDate == occurrence.end)
    }

    @Test func nonFulldaySpanningWholeLocalDaysDisplaysDatesOnly() throws {
        let start = Calendar.current.startOfDay(for: ScheduledAbsenceFixtures.date("2026-05-04T12:00:00Z"))
        let end = try #require(Calendar.current.date(byAdding: .day, value: 5, to: start))
        let occurrence = ScheduledAbsenceOccurrence(start: start, end: end, fullday: false)

        #expect(!occurrence.displaysTime)
        #expect(occurrence.lastDisplayedDate == end.addingTimeInterval(-1))
    }

    @Test func timedOccurrenceDisplaysTime() {
        let occurrence = ScheduledAbsenceFixtures.entry(
            start: "2026-05-07T08:00:00Z",
            end: "2026-05-07T18:00:00Z"
        ).occurrence
        let now = ScheduledAbsenceFixtures.date("2026-05-05T12:00:00Z")

        #expect(occurrence.displaysTime)
        #expect(occurrence.formattedStart(now: now).contains(occurrence.start.formatted(.dateTime.hour().minute())))
        #expect(occurrence.formattedEnd(now: now).contains(occurrence.end.formatted(.dateTime.hour().minute())))
    }

    @Test func yearDependsOnNow() {
        let occurrence = ScheduledAbsenceFixtures.entry(
            start: "2026-05-04T00:00:00Z",
            end: "2026-05-09T00:00:00Z",
            fullday: true
        ).occurrence

        #expect(!occurrence.formattedStart(now: ScheduledAbsenceFixtures.date("2026-05-01T12:00:00Z")).contains("2026"))
        #expect(occurrence.formattedStart(now: ScheduledAbsenceFixtures.date("2025-12-01T12:00:00Z")).contains("2026"))
    }
}

@Suite("ScheduledAbsenceSummary")
struct ScheduledAbsenceSummaryTests {
    private let now = ScheduledAbsenceFixtures.date("2026-05-05T12:00:00Z")
    private let ongoing = ScheduledAbsenceFixtures.entry(
        start: "2026-05-04T00:00:00Z",
        end: "2026-05-09T00:00:00Z",
        fullday: true,
        autoReplyContent: "Away"
    )
    private let upcoming = ScheduledAbsenceFixtures.entry(start: "2026-05-07T08:00:00Z", end: "2026-05-07T18:00:00Z")
    private let past = ScheduledAbsenceFixtures.entry(start: "2026-05-01T08:00:00Z", end: "2026-05-02T08:00:00Z")
    private let alice = ScheduledAbsenceRecipient(email: "a@x.com", name: "Alice")

    private func recipient(_ email: String) -> ScheduledAbsenceRecipient {
        return ScheduledAbsenceRecipient(email: email, name: "")
    }

    @Test func emptyWhenNoCurrentOrFutureAbsence() {
        #expect(ScheduledAbsenceSummary(absencesByEmail: ["a@x.com": [past]], orderedRecipients: [alice], now: now) == nil)
    }

    @Test func ongoingWinsOverUpcoming() throws {
        let summary = try #require(ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [upcoming], "b@x.com": [ongoing]],
            orderedRecipients: [recipient("a@x.com"), recipient("b@x.com")],
            now: now
        ))
        #expect(summary.state == .ongoing)
        #expect(summary.singleAbsentRecipient == .init(recipient: recipient("b@x.com"), entry: ongoing, now: now))
        #expect(summary.actionTitle != nil)
    }

    @Test func upcomingSingleWithoutAutoReplyHasNoAction() throws {
        let summary = try #require(
            ScheduledAbsenceSummary(absencesByEmail: ["a@x.com": [upcoming]], orderedRecipients: [alice], now: now)
        )
        #expect(summary.state == .upcoming)
        #expect(summary.singleAbsentRecipient == .init(recipient: alice, entry: upcoming, now: now))
        #expect(summary.actionTitle == nil)
        #expect(summary.bannerText.contains("Alice"))
    }

    @Test func bannerFormatsDatesRelativeToNow() throws {
        let previousYear = ScheduledAbsenceFixtures.date("2025-12-01T12:00:00Z")
        let summary = try #require(
            ScheduledAbsenceSummary(absencesByEmail: ["a@x.com": [upcoming]], orderedRecipients: [alice], now: previousYear)
        )
        #expect(summary.bannerText.contains("2026"))
    }

    @Test func displaysEmailWhenNameIsMissingOrEqualToEmail() throws {
        let summary = try #require(ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [upcoming], "b@x.com": [upcoming]],
            orderedRecipients: [recipient("a@x.com"), ScheduledAbsenceRecipient(email: "b@x.com", name: "B@X.com")],
            now: now
        ))
        #expect(summary.absentRecipients.map(\.name) == ["", ""])
        #expect(summary.absentRecipients.map(\.displayName) == ["a@x.com", "b@x.com"])
    }

    @Test func multipleKeepsOneAbsencePerRecipientInOrder() throws {
        let secondOngoing = ScheduledAbsenceFixtures.entry(start: "2026-05-05T08:00:00Z", end: "2026-05-05T18:00:00Z")
        let summary = try #require(ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [ongoing, upcoming], "b@x.com": [secondOngoing]],
            orderedRecipients: [recipient("b@x.com"), recipient("a@x.com")],
            now: now
        ))
        #expect(summary.state == .ongoing)
        #expect(summary.absentRecipients == [
            .init(recipient: recipient("b@x.com"), entry: secondOngoing, now: now),
            .init(recipient: recipient("a@x.com"), entry: ongoing, now: now)
        ])
        #expect(summary.singleAbsentRecipient == nil)
    }

    @Test func keepsFirstUpcomingAbsenceOfSameRecipient() throws {
        let otherUpcoming = ScheduledAbsenceFixtures.entry(start: "2026-05-06T08:00:00Z", end: "2026-05-06T18:00:00Z")
        let summary = try #require(ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [upcoming, otherUpcoming]],
            orderedRecipients: [recipient("a@x.com")],
            now: now
        ))
        #expect(summary.singleAbsentRecipient == .init(recipient: recipient("a@x.com"), entry: otherUpcoming, now: now))
    }

    @Test func sortsFulldayAndTimedAbsencesByLocalStart() throws {
        let losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let fullday = ScheduledAbsenceFixtures.entry(start: "2026-05-06T00:00:00Z", end: "2026-05-07T00:00:00Z", fullday: true)
        let timed = ScheduledAbsenceFixtures.entry(start: "2026-05-06T03:00:00Z", end: "2026-05-06T05:00:00Z")

        let entries = ScheduledAbsenceSummary.relevantEntryByEmail(
            absencesByEmail: ["a@x.com": [fullday, timed]],
            now: now,
            timeZone: losAngeles
        )
        #expect(entries == ["a@x.com": timed])
    }

    @Test func descriptionsKeepOneAbsencePerRecipientIncludingUpcoming() throws {
        let summary = try #require(ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [upcoming, ongoing], "b@x.com": [upcoming], "c@x.com": [past]],
            orderedRecipients: [recipient("a@x.com"), recipient("b@x.com"), recipient("c@x.com")],
            now: now
        ))
        #expect(summary.absentRecipients.map(\.email) == ["a@x.com"])
        #expect(summary.descriptionsByEmail == [
            "a@x.com": ongoing.occurrence.chipDescription(now: now),
            "b@x.com": upcoming.occurrence.chipDescription(now: now)
        ])
    }
}

@Suite("ScheduledAbsenceLookup")
struct ScheduledAbsenceLookupTests {
    final class MockFetcher: MailApiScheduledAbsenceFetchable, @unchecked Sendable {
        private let lock = NSLock()
        private var _requests = [(emails: [String], from: Date, to: Date)]()
        var response = [String: [ScheduledAbsenceEntry]]()
        var shouldFail = false

        var requestedEmails: [[String]] {
            lock.withLock { _requests.map(\.emails) }
        }

        var requestedWindows: [(from: Date, to: Date)] {
            lock.withLock { _requests.map { ($0.from, $0.to) } }
        }

        func activeScheduledAbsences(emails: [String], from: Date, to: Date) async throws -> [String: [ScheduledAbsenceEntry]] {
            lock.withLock { _requests.append((emails, from, to)) }
            if shouldFail {
                throw MailError.unknownError
            }
            return emails.reduce(into: [String: [ScheduledAbsenceEntry]]()) { result, email in
                result[email] = response[email] ?? []
            }
        }
    }

    private let absence = ScheduledAbsenceFixtures.entry(start: "2026-05-06T08:00:00Z", end: "2026-05-06T18:00:00Z")

    @Test func windowEndsAtEndOfLookAheadDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Zurich"))
        let date = ScheduledAbsenceFixtures.date("2026-05-05T12:00:00Z")

        let window = ScheduledAbsenceLookup.window(startingAt: date, calendar: calendar)

        #expect(window.from == date)
        #expect(window.to == ScheduledAbsenceFixtures.date("2026-05-08T21:59:59Z"))
    }

    @Test func recipientsAreDedupedNamedAndLimited() {
        let candidates = [
            ScheduledAbsenceRecipient(email: "A@x.com", name: ""),
            ScheduledAbsenceRecipient(email: "", name: "Nobody"),
            ScheduledAbsenceRecipient(email: "a@x.com", name: "Alice"),
            ScheduledAbsenceRecipient(email: "a@x.com", name: "Other")
        ] + (0 ..< 30).map { ScheduledAbsenceRecipient(email: "user\($0)@x.com", name: "") }

        let recipients = ScheduledAbsenceLookup.recipients(candidates)

        #expect(recipients.count == ScheduledAbsenceLookup.maxEmails)
        #expect(recipients.first == ScheduledAbsenceRecipient(email: "a@x.com", name: "Alice"))
        #expect(recipients.dropFirst().first?.email == "user0@x.com")
    }

    @Test func requestsWindowAndDropsRecipientsWithoutAbsence() async throws {
        let fetcher = MockFetcher()
        fetcher.response = ["a@x.com": [absence]]
        let date = ScheduledAbsenceFixtures.date("2026-05-05T12:00:00Z")

        let result = try await fetcher.activeScheduledAbsences(emails: ["a@x.com", "b@x.com"], startingAt: date)

        #expect(result == ["a@x.com": [absence]])
        #expect(fetcher.requestedEmails == [["a@x.com", "b@x.com"]])
        #expect(fetcher.requestedWindows.first?.from == date)
        #expect(fetcher.requestedWindows.first?.to == ScheduledAbsenceLookup.window(startingAt: date).to)
    }
}
