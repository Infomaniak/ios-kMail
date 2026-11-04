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
@testable import MailCore
import Testing

enum ScheduledAbsenceFixtures {
    static func date(_ string: String) -> Date {
        return ScheduledAbsenceDateParser.date(from: string)!
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
            },
            {
                "absence": { "uuid": "broken" },
                "occurrence": { "start": "not a date", "end": "2026-05-09T00:00:00+00:00", "fullday": false }
            }
        ],
        "bob@example.com": null,
        "carol@example.com": [
            {
                "absence": { "uuid": "c1" },
                "occurrence": { "start": "2026-09-29T10:00:00.500+02:00", "end": "2026-09-30T18:00:00+02:00" }
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

    @Test func decodesResponseWithNullAndMalformedEntries() throws {
        let response = try decoder.decode(ScheduledAbsencesResponse.self, from: Data(json.utf8))
        let absences = response.absencesByEmail

        #expect(absences["bob@example.com"]?.isEmpty == true)
        #expect(absences["Alice@Example.com"] == nil)

        let alice = try #require(absences["alice@example.com"])
        #expect(alice.count == 1)
        #expect(alice[0].absence.statusEmoji == "palm_tree")
        #expect(alice[0].absence.statusText == "En vacances")
        #expect(alice[0].absence.disableKchatNotification)
        #expect(alice[0].absence.createdAt == ScheduledAbsenceFixtures.date("2026-04-01T08:00:00Z"))
        #expect(alice[0].absence.updatedAt == nil)
        #expect(alice[0].occurrence.fullday)
        #expect(alice[0].occurrence.end == ScheduledAbsenceFixtures.date("2026-05-09T00:00:00Z"))

        let carol = try #require(absences["carol@example.com"]?.first)
        #expect(carol.absence.statusText == nil)
        #expect(carol.absence.autoReplyContent == nil)
        #expect(!carol.absence.autoDeclineInvitation)
        #expect(!carol.occurrence.fullday)
        #expect(carol.occurrence.start == ScheduledAbsenceFixtures.date("2026-09-29T08:00:00.500Z"))
    }
}

@Suite("ScheduledAbsenceFormatting")
struct ScheduledAbsenceFormattingTests {
    private let french = Locale(identifier: "fr_FR")

    @Test func fulldayUsesUTCAndExclusiveEnd() {
        let occurrence = ScheduledAbsenceFixtures.entry(
            start: "2026-05-04T00:00:00+00:00",
            end: "2026-05-09T00:00:00+00:00",
            fullday: true
        ).occurrence

        #expect(occurrence.formattedReturnDate(locale: french) == "samedi 9 mai")
        #expect(occurrence.formattedStartDay(locale: french) == "4 mai")
        #expect(occurrence.formattedLastDisplayedDay(locale: french) == "8 mai")
    }

    @Test func nonFulldayKeepsEnd() {
        let occurrence = ScheduledAbsenceFixtures.entry(
            start: "2026-05-04T12:00:00+00:00",
            end: "2026-05-08T12:00:00+00:00"
        ).occurrence

        #expect(occurrence.lastDisplayedDate == occurrence.end)
        #expect(occurrence.returnDate == occurrence.end)
    }

    @Test func fulldayStatusComparesLocalCalendarDates() throws {
        let occurrence = ScheduledAbsenceFixtures.entry(
            start: "2026-05-04T00:00:00+00:00",
            end: "2026-05-09T00:00:00+00:00",
            fullday: true
        ).occurrence
        let zurich = try #require(TimeZone(identifier: "Europe/Zurich"))
        let newYork = try #require(TimeZone(identifier: "America/New_York"))

        // May 4th 00:30 in Zurich is still May 3rd in UTC
        #expect(occurrence.isOngoing(at: ScheduledAbsenceFixtures.date("2026-05-03T22:30:00Z"), timeZone: zurich))
        // May 8th 21:00 in New York is already May 9th in UTC
        #expect(occurrence.isOngoing(at: ScheduledAbsenceFixtures.date("2026-05-09T01:00:00Z"), timeZone: newYork))
        // May 3rd 23:30 in Zurich
        #expect(occurrence.isUpcoming(at: ScheduledAbsenceFixtures.date("2026-05-03T21:30:00Z"), timeZone: zurich))
        // May 9th 00:30 in Zurich: back
        let backDate = ScheduledAbsenceFixtures.date("2026-05-08T22:30:00Z")
        #expect(!occurrence.isOngoing(at: backDate, timeZone: zurich) && !occurrence.isUpcoming(at: backDate, timeZone: zurich))
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
        let summary = ScheduledAbsenceSummary(absencesByEmail: ["a@x.com": [past]], orderedEmails: ["a@x.com"], now: now)
        #expect(summary.mode == nil)
        #expect(summary.displayedEntries.isEmpty)
        #expect(summary.bannerText(displayName: "A") == nil)
    }

    @Test func ongoingWinsOverUpcoming() {
        let summary = ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [upcoming], "b@x.com": [ongoing]],
            orderedEmails: ["A@x.com", "b@x.com"],
            now: now
        )
        #expect(summary.mode == .ongoingSingle(.init(email: "b@x.com", entry: ongoing)))
        #expect(summary.isSingle)
        #expect(!summary.isUpcoming)
        #expect(summary.actionTitle != nil)
    }

    @Test func upcomingSingleWithoutAutoReplyHasNoAction() {
        let summary = ScheduledAbsenceSummary(absencesByEmail: ["a@x.com": [upcoming]], orderedEmails: ["a@x.com"], now: now)
        #expect(summary.mode == .upcomingSingle(.init(email: "a@x.com", entry: upcoming)))
        #expect(summary.isUpcoming)
        #expect(summary.actionTitle == nil)
        #expect(summary.bannerText(displayName: nil)?.contains("a@x.com") == true)
    }

    @Test func autoReplyAlreadyDisplayedHidesAction() async {
        var summary = ScheduledAbsenceSummary(absencesByEmail: ["a@x.com": [ongoing]], orderedEmails: ["a@x.com"], now: now)
        let absence = ScheduledAbsence(uuid: "1", autoReplyContent: "  I am  away\nuntil Friday. ")
        let signature = "<div class=\"\(Constants.signatureHTMLClass)\">Alice</div>"

        #expect(await absence.isAutoReplyDisplayed(in: [.init(
            content: "<p>i am away</p> UNTIL friday.\(signature)",
            isHTML: true
        )]))
        #expect(await absence.isAutoReplyDisplayed(in: [.init(content: "I am away until Friday.", isHTML: false)]))
        #expect(await !absence.isAutoReplyDisplayed(in: [.init(content: "I am away until Friday. Thanks", isHTML: false)]))

        summary.isAutoReplyAlreadyDisplayed = true
        #expect(summary.actionTitle == nil)
    }

    @Test func multipleCountsEmailEntryPairsInRecipientOrder() {
        let secondOngoing = ScheduledAbsenceFixtures.entry(start: "2026-05-05T08:00:00Z", end: "2026-05-05T18:00:00Z")
        let summary = ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [ongoing, upcoming], "b@x.com": [secondOngoing]],
            orderedEmails: ["b@x.com", "a@x.com", "a@x.com"],
            now: now
        )
        #expect(summary.mode == .ongoingMultiple([
            .init(email: "b@x.com", entry: secondOngoing),
            .init(email: "a@x.com", entry: ongoing)
        ]))
        #expect(!summary.isSingle)
        #expect(summary.recipientsTitle != nil)
    }

    @Test func upcomingMultipleForSameRecipient() {
        let otherUpcoming = ScheduledAbsenceFixtures.entry(start: "2026-05-06T08:00:00Z", end: "2026-05-06T18:00:00Z")
        let summary = ScheduledAbsenceSummary(
            absencesByEmail: ["a@x.com": [upcoming, otherUpcoming]],
            orderedEmails: ["a@x.com"],
            now: now
        )
        #expect(summary.mode == .upcomingMultiple([
            .init(email: "a@x.com", entry: otherUpcoming),
            .init(email: "a@x.com", entry: upcoming)
        ]))
    }
}

@Suite("ScheduledAbsenceProvider")
struct ScheduledAbsenceProviderTests {
    final class MockFetcher: MailApiScheduledAbsenceFetchable, @unchecked Sendable {
        var requestedEmails = [[String]]()
        var response = [String: [ScheduledAbsenceEntry]]()
        var shouldFail = false

        func activeScheduledAbsences(emails: [String], from: Date, to: Date) async throws -> [String: [ScheduledAbsenceEntry]] {
            requestedEmails.append(emails)
            if shouldFail {
                throw MailError.unknownError
            }
            return response.filter { emails.contains($0.key) }
        }
    }

    struct MockFeatureFlags: FeatureFlagsManageable {
        let enabled: Bool

        func isEnabled(_ feature: FeatureFlag) -> Bool {
            return enabled
        }

        func feature(_ feature: FeatureFlag, on: () -> Void, off: (() -> Void)?) {}

        func fetchFlags() async throws {}
    }

    final class Clock: @unchecked Sendable {
        var now = ScheduledAbsenceFixtures.date("2026-05-05T12:00:00Z")
    }

    private let absence = ScheduledAbsenceFixtures.entry(start: "2026-05-06T08:00:00Z", end: "2026-05-06T18:00:00Z")

    private func makeProvider(fetcher: MockFetcher, enabled: Bool = true, clock: Clock = Clock()) -> ScheduledAbsenceProvider {
        return ScheduledAbsenceProvider(apiFetcher: fetcher, featureFlagsManager: MockFeatureFlags(enabled: enabled)) {
            clock.now
        }
    }

    @Test func returnsEmptyWhenFeatureDisabled() async {
        let fetcher = MockFetcher()
        let provider = makeProvider(fetcher: fetcher, enabled: false)

        #expect(await provider.absences(for: ["a@x.com"]).isEmpty)
        #expect(await provider.absences(for: ["a@x.com"], from: .now, to: .now.addingTimeInterval(60)).isEmpty)
        #expect(fetcher.requestedEmails.isEmpty)
    }

    @Test func batchesDedupesAndCaches() async {
        let fetcher = MockFetcher()
        fetcher.response = ["a@x.com": [absence]]
        let provider = makeProvider(fetcher: fetcher)

        let result = await provider.absences(for: ["A@x.com", "a@x.com", "b@x.com"])
        #expect(result == ["a@x.com": [absence]])
        #expect(fetcher.requestedEmails == [["a@x.com", "b@x.com"]])
        #expect(provider.cachedAbsences(for: "A@X.com") == [absence])

        _ = await provider.absences(for: ["a@x.com", "b@x.com", "c@x.com"])
        #expect(fetcher.requestedEmails.last == ["c@x.com"])
    }

    @Test func limitsToMaxEmails() async {
        let fetcher = MockFetcher()
        let provider = makeProvider(fetcher: fetcher)

        _ = await provider.absences(for: (0 ..< 30).map { "user\($0)@x.com" })
        #expect(fetcher.requestedEmails.first?.count == ScheduledAbsenceProvider.maxEmails)
    }

    @Test func refetchesAfterTTLOrWhenWindowNotCovered() async {
        let fetcher = MockFetcher()
        let clock = Clock()
        let provider = makeProvider(fetcher: fetcher, clock: clock)

        _ = await provider.absences(for: ["a@x.com"])
        clock.now = clock.now.addingTimeInterval(60)
        _ = await provider.absences(for: ["a@x.com"])
        #expect(fetcher.requestedEmails.count == 1)

        clock.now = clock.now.addingTimeInterval(ScheduledAbsenceProvider.cacheTTL)
        _ = await provider.absences(for: ["a@x.com"])
        #expect(fetcher.requestedEmails.count == 2)

        _ = await provider.absences(for: ["a@x.com"], forceRefresh: true)
        #expect(fetcher.requestedEmails.count == 3)

        // Next day: the cached window no longer covers the new one
        clock.now = clock.now.addingTimeInterval(24 * 60 * 60 - ScheduledAbsenceProvider.cacheTTL - 120)
        _ = await provider.absences(for: ["a@x.com"])
        #expect(fetcher.requestedEmails.count == 4)
    }

    @Test func swallowsErrorsAndBypassesCacheForCustomWindow() async {
        let fetcher = MockFetcher()
        fetcher.shouldFail = true
        let provider = makeProvider(fetcher: fetcher)

        #expect(await provider.absences(for: ["a@x.com"]).isEmpty)

        fetcher.shouldFail = false
        fetcher.response = ["a@x.com": [absence]]
        let from = ScheduledAbsenceFixtures.date("2026-05-06T00:00:00Z")
        let result = await provider.absences(for: ["a@x.com"], from: from, to: from.addingTimeInterval(3 * 24 * 60 * 60))
        #expect(result == ["a@x.com": [absence]])
        #expect(provider.cachedAbsences(for: "a@x.com").isEmpty)
    }
}
