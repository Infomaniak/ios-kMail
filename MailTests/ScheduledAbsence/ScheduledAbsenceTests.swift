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
        "Alice@Example.com": [
            {
                "absence": {
                    "uuid": "a1",
                    "status_emoji": "palm_tree",
                    "status_text": "En vacances",
                    "auto_reply_content": "Back soon",
                    "disable_kchat_notification": true,
                    "auto_decline_invitation": false,
                    "created_at": "2026-04-01T10:00:00+02:00",
                    "updated_at": null,
                    "event": { "id": 1 }
                },
                "occurrence": { "start": "2026-05-04T00:00:00+00:00", "end": "2026-05-09T00:00:00+00:00", "fullday": true }
            }
        ],
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
                "occurrence": { "start": "2026-09-29T10:00:00+02:00", "end": "2026-09-30T18:00:00+02:00" }
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
        let response = try decoder.decode(ScheduledAbsencesResponse.self, from: Data(json.utf8))
        let absences = response.absencesByEmail

        #expect(absences["bob@example.com"]?.isEmpty == true)
        #expect(absences["Alice@Example.com"] == nil)

        let alice = try #require(absences["alice@example.com"])
        #expect(alice.count == 1)
        #expect(alice[0].absence.statusText == "En vacances")
        #expect(alice[0].occurrence.fullday)
        #expect(alice[0].occurrence.end == ScheduledAbsenceFixtures.date("2026-05-09T00:00:00Z"))

        let carol = try #require(absences["carol@example.com"]?.first)
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

    @Test func nonFulldayKeepsEnd() {
        let occurrence = ScheduledAbsenceFixtures.entry(
            start: "2026-05-04T12:00:00+00:00",
            end: "2026-05-08T12:00:00+00:00"
        ).occurrence

        #expect(occurrence.lastDisplayedDate == occurrence.end)
    }

    @Test func nonFulldayEndingAtLocalMidnightDisplaysPreviousDay() throws {
        let start = ScheduledAbsenceFixtures.date("2026-05-04T12:00:00Z")
        let end = try #require(Calendar.current.date(byAdding: .day, value: 5, to: Calendar.current.startOfDay(for: start)))
        let occurrence = ScheduledAbsenceOccurrence(start: start, end: end, fullday: false)

        #expect(occurrence.lastDisplayedDate < end)
        #expect(Calendar.current.isDate(occurrence.lastDisplayedDate, inSameDayAs: end.addingTimeInterval(-3600)))
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

    @Test func emptyWhenNoCurrentOrFutureAbsence() {
        #expect(ScheduledAbsenceSummary(absencesByEmail: ["a@x.com": [past]], orderedEmails: ["a@x.com"], now: now) == nil)
    }

    @Test func ongoingWinsOverUpcoming() throws {
        let summary = try #require(ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [upcoming], "b@x.com": [ongoing]],
            orderedEmails: ["A@x.com", "b@x.com"],
            now: now
        ))
        #expect(summary.state == .ongoing)
        #expect(summary.singleItem == .init(email: "b@x.com", entry: ongoing))
        #expect(summary.actionTitle != nil)
    }

    @Test func upcomingSingleWithoutAutoReplyHasNoAction() throws {
        let summary = try #require(
            ScheduledAbsenceSummary(absencesByEmail: ["a@x.com": [upcoming]], orderedEmails: ["a@x.com"], now: now)
        )
        #expect(summary.state == .upcoming)
        #expect(summary.singleItem == .init(email: "a@x.com", entry: upcoming))
        #expect(summary.actionTitle == nil)
        #expect(summary.bannerText { _ in "Alice" }.contains("Alice"))
    }

    @Test func multipleKeepsOneAbsencePerRecipientInOrder() throws {
        let secondOngoing = ScheduledAbsenceFixtures.entry(start: "2026-05-05T08:00:00Z", end: "2026-05-05T18:00:00Z")
        let summary = try #require(ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [ongoing, upcoming], "b@x.com": [secondOngoing]],
            orderedEmails: ["b@x.com", "a@x.com", "a@x.com"],
            now: now
        ))
        #expect(summary.state == .ongoing)
        #expect(summary.items == [
            .init(email: "b@x.com", entry: secondOngoing),
            .init(email: "a@x.com", entry: ongoing)
        ])
        #expect(summary.singleItem == nil)
    }

    @Test func keepsFirstUpcomingAbsenceOfSameRecipient() throws {
        let otherUpcoming = ScheduledAbsenceFixtures.entry(start: "2026-05-06T08:00:00Z", end: "2026-05-06T18:00:00Z")
        let summary = try #require(ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [upcoming, otherUpcoming]],
            orderedEmails: ["a@x.com"],
            now: now
        ))
        #expect(summary.singleItem == .init(email: "a@x.com", entry: otherUpcoming))
    }

    @Test func mergesChainedAbsencesOfSameRecipient() throws {
        let first = ScheduledAbsenceFixtures.entry(start: "2026-05-04T00:00:00Z", end: "2026-05-06T00:00:00Z", fullday: true)
        let second = ScheduledAbsenceFixtures.entry(start: "2026-05-06T00:00:00Z", end: "2026-05-09T00:00:00Z", fullday: true)
        let later = ScheduledAbsenceFixtures.entry(start: "2026-05-12T00:00:00Z", end: "2026-05-14T00:00:00Z", fullday: true)
        let summary = ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [later, second, first]],
            orderedEmails: ["a@x.com"],
            now: now
        )

        let item = try #require(summary?.singleItem)
        #expect(item.entry.absence == first.absence)
        #expect(item.entry.occurrence.start == first.occurrence.start)
        #expect(item.entry.occurrence.end == second.occurrence.end)
    }

    @Test func descriptionsKeepOneAbsencePerRecipient() {
        let descriptions = ScheduledAbsenceSummary.descriptionsByEmail(
            absencesByEmail: ["A@x.com": [upcoming, ongoing], "b@x.com": [past]],
            now: now
        )
        #expect(descriptions == ["a@x.com": ongoing.occurrence.chipDescription(now: now)])
    }
}
