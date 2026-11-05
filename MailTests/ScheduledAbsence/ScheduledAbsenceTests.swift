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
@testable import Infomaniak_Mail
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

    @Test func autoReplyMatchingIgnoresCaseWhitespaceAndSignature() async {
        let absence = ScheduledAbsence(uuid: "1", autoReplyContent: "  I am  away\nuntil Friday. ")
        let signature = "<div class=\"\(Constants.signatureHTMLClass)\">Alice</div>"

        #expect(await absence.isAutoReplyDisplayed(in: [.init(
            content: "<p>i am away</p> UNTIL friday.\(signature)",
            isHTML: true
        )]))
        #expect(await absence.isAutoReplyDisplayed(in: [.init(content: "I am away until Friday.", isHTML: false)]))
        #expect(await !absence.isAutoReplyDisplayed(in: [.init(content: "I am away until Friday. Thanks", isHTML: false)]))
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

@Suite("ScheduledAbsenceProvider")
struct ScheduledAbsenceProviderTests {
    final class MockFetcher: MailApiScheduledAbsenceFetchable, @unchecked Sendable {
        private let lock = NSLock()
        private var _requestedEmails = [[String]]()
        var response = [String: [ScheduledAbsenceEntry]]()
        var shouldFail = false
        var gate: (@Sendable () async -> Void)?

        var requestedEmails: [[String]] {
            lock.withLock { _requestedEmails }
        }

        func activeScheduledAbsences(emails: [String], from: Date, to: Date) async throws -> [String: [ScheduledAbsenceEntry]] {
            lock.withLock { _requestedEmails.append(emails) }
            await gate?()
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
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return ScheduledAbsenceProvider(
            apiFetcher: fetcher,
            featureFlagsManager: MockFeatureFlags(enabled: enabled),
            calendar: calendar
        ) {
            clock.now
        }
    }

    @Test func returnsEmptyWhenFeatureDisabled() async {
        let fetcher = MockFetcher()
        let provider = makeProvider(fetcher: fetcher, enabled: false)

        #expect(await provider.absences(for: ["a@x.com"]).isEmpty)
        #expect(await provider.absences(for: ["a@x.com"], at: .now).isEmpty)
        #expect(fetcher.requestedEmails.isEmpty)
    }

    @Test func batchesDedupesAndCaches() async {
        let fetcher = MockFetcher()
        fetcher.response = ["a@x.com": [absence]]
        let provider = makeProvider(fetcher: fetcher)

        let result = await provider.absences(for: ["A@x.com", "a@x.com", "b@x.com"])
        #expect(result == ["a@x.com": [absence]])
        #expect(fetcher.requestedEmails == [["a@x.com", "b@x.com"]])

        _ = await provider.absences(for: ["a@x.com", "b@x.com", "c@x.com"])
        #expect(fetcher.requestedEmails.last == ["c@x.com"])
    }

    @Test func limitsToMaxEmails() async {
        let fetcher = MockFetcher()
        let provider = makeProvider(fetcher: fetcher)

        _ = await provider.absences(for: (0 ..< 30).map { "user\($0)@x.com" })
        #expect(fetcher.requestedEmails.first?.count == ScheduledAbsenceProvider.maxEmails)
    }

    @Test func refetchesAfterTTL() async {
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
    }

    @Test func refetchesWithinTTLWhenWindowNotCovered() async {
        let fetcher = MockFetcher()
        let clock = Clock()
        clock.now = ScheduledAbsenceFixtures.date("2026-05-05T23:55:00Z")
        let provider = makeProvider(fetcher: fetcher, clock: clock)

        _ = await provider.absences(for: ["a@x.com"])
        clock.now = clock.now.addingTimeInterval(10 * 60)
        _ = await provider.absences(for: ["a@x.com"])

        #expect(fetcher.requestedEmails.count == 2)
    }

    @Test func swallowsErrorsAndRetriesAfterDelay() async {
        let fetcher = MockFetcher()
        fetcher.shouldFail = true
        let clock = Clock()
        let provider = makeProvider(fetcher: fetcher, clock: clock)

        #expect(await provider.absences(for: ["a@x.com"]).isEmpty)
        #expect(await provider.absences(for: ["a@x.com"]).isEmpty)
        #expect(fetcher.requestedEmails.count == 1)

        fetcher.shouldFail = false
        fetcher.response = ["a@x.com": [absence]]
        clock.now = clock.now.addingTimeInterval(ScheduledAbsenceProvider.failureRetryDelay)
        #expect(await provider.absences(for: ["a@x.com"]) == ["a@x.com": [absence]])
        #expect(fetcher.requestedEmails.count == 2)
    }

    @Test func bypassesCacheForScheduledDate() async {
        let fetcher = MockFetcher()
        fetcher.response = ["a@x.com": [absence]]
        let provider = makeProvider(fetcher: fetcher)

        _ = await provider.absences(for: ["a@x.com"])
        let from = ScheduledAbsenceFixtures.date("2026-05-06T00:00:00Z")
        let result = await provider.absences(for: ["a@x.com"], at: from)

        #expect(result == ["a@x.com": [absence]])
        #expect(fetcher.requestedEmails.count == 2)
    }

    @Test func sharesInFlightRequestForConcurrentLookups() async throws {
        let fetcher = MockFetcher()
        fetcher.response = ["a@x.com": [absence]]
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        fetcher.gate = {
            for await _ in stream {
                break
            }
        }
        let provider = makeProvider(fetcher: fetcher)

        async let first = provider.absences(for: ["a@x.com"])
        async let second = provider.absences(for: ["a@x.com"])
        // Leave time to the second lookup to start a duplicate request if requests weren't shared
        try await Task.sleep(nanoseconds: 200_000_000)
        continuation.finish()

        let results = await [first, second]
        #expect(results == [["a@x.com": [absence]], ["a@x.com": [absence]]])
        #expect(fetcher.requestedEmails == [["a@x.com"]])
    }
}

@MainActor
@Suite("ComposeScheduledAbsence")
struct ComposeScheduledAbsenceTests {
    private let scheduleDate = ScheduledAbsenceFixtures.date("2026-05-05T12:00:00Z")
    private let absence = ScheduledAbsenceFixtures.entry(start: "2026-05-06T08:00:00Z", end: "2026-05-06T18:00:00Z")

    private func makeDraft(to: [Recipient], cc: [Recipient] = [], bcc: [Recipient] = []) -> Draft {
        let draft = Draft()
        draft.to.append(objectsIn: to)
        draft.cc.append(objectsIn: cc)
        draft.bcc.append(objectsIn: bcc)
        draft.scheduleDate = scheduleDate
        return draft
    }

    private func makeViewModel(
        fetcher: ScheduledAbsenceProviderTests.MockFetcher,
        contactNames: [String: String] = [:]
    ) -> ComposeScheduledAbsenceViewModel {
        let provider = ScheduledAbsenceProvider(
            apiFetcher: fetcher,
            featureFlagsManager: ScheduledAbsenceProviderTests.MockFeatureFlags(enabled: true)
        )
        return ComposeScheduledAbsenceViewModel(provider: provider, debounceDuration: .zero) { contactNames[$0] }
    }

    @Test func requestDedupesAndCapsRecipients() {
        let draft = makeDraft(
            to: [Recipient(email: "A@x.com", name: "Alice"), Recipient(email: "", name: "")],
            cc: [Recipient(email: "a@x.com", name: ""), Recipient(email: "b@x.com", name: "")],
            bcc: (0 ..< 30).map { Recipient(email: "user\($0)@x.com", name: "") }
        )

        let request = ComposeScheduledAbsenceRequest(draft: draft)
        #expect(request.recipients.count == ScheduledAbsenceProvider.maxEmails)
        #expect(Array(request.recipients.prefix(3).map(\.email)) == ["a@x.com", "b@x.com", "user0@x.com"])
        #expect(request.recipients.first?.name == "Alice")
        #expect(request.scheduleDate == scheduleDate)
    }

    @Test func updateComputesSummaryAndDescriptions() async {
        let fetcher = ScheduledAbsenceProviderTests.MockFetcher()
        fetcher.response = ["a@x.com": [absence]]
        let viewModel = makeViewModel(fetcher: fetcher)

        await viewModel.update(ComposeScheduledAbsenceRequest(draft: makeDraft(to: [Recipient(email: "A@x.com", name: "")])))
        #expect(viewModel.summary?.singleItem?.email == "a@x.com")
        #expect(viewModel.chipDescriptionsByEmail == ["a@x.com": absence.occurrence.chipDescription(now: scheduleDate)])

        await viewModel.update(ComposeScheduledAbsenceRequest(draft: makeDraft(to: [])))
        #expect(viewModel.summary == nil)
        #expect(viewModel.chipDescriptionsByEmail.isEmpty)
        #expect(fetcher.requestedEmails.count == 1)
    }

    @Test func removedRecipientIsPrunedBeforeFetching() async {
        let fetcher = ScheduledAbsenceProviderTests.MockFetcher()
        fetcher.response = ["a@x.com": [absence], "b@x.com": [absence]]
        let viewModel = makeViewModel(fetcher: fetcher)
        let alice = Recipient(email: "a@x.com", name: "")
        let bob = Recipient(email: "b@x.com", name: "")

        await viewModel.update(ComposeScheduledAbsenceRequest(draft: makeDraft(to: [alice, bob])))
        #expect(viewModel.summary?.items.count == 2)

        // The cancelled update never applies a fetch result: only the immediate pruning is visible
        fetcher.shouldFail = true
        let request = ComposeScheduledAbsenceRequest(draft: makeDraft(to: [bob]))
        let task = Task { await viewModel.update(request) }
        task.cancel()
        await task.value

        #expect(viewModel.summary?.singleItem?.email == "b@x.com")
        #expect(Array(viewModel.chipDescriptionsByEmail.keys) == ["b@x.com"])
    }

    @Test func displayNamePrefersDraftNameThenContactName() async {
        let fetcher = ScheduledAbsenceProviderTests.MockFetcher()
        let viewModel = makeViewModel(fetcher: fetcher, contactNames: ["b@x.com": "Bob", "c@x.com": "Carol"])
        let draft = makeDraft(to: [
            Recipient(email: "a@x.com", name: "Alice"),
            Recipient(email: "b@x.com", name: ""),
            Recipient(email: "c@x.com", name: "C@x.com"),
            Recipient(email: "d@x.com", name: "")
        ])
        await viewModel.update(ComposeScheduledAbsenceRequest(draft: draft))

        #expect(viewModel.displayName(for: "a@x.com") == "Alice")
        #expect(viewModel.displayName(for: "b@x.com") == "Bob")
        #expect(viewModel.displayName(for: "c@x.com") == "Carol")
        #expect(viewModel.displayName(for: "d@x.com") == "d@x.com")
    }
}

@MainActor
@Suite("ThreadScheduledAbsenceViewModel")
struct ThreadScheduledAbsenceViewModelTests {
    private let now = ScheduledAbsenceFixtures.date("2026-05-05T12:00:00Z")
    private let ongoing = ScheduledAbsenceFixtures.entry(
        uuid: "ongoing",
        start: "2026-05-04T00:00:00Z",
        end: "2026-05-09T00:00:00Z",
        fullday: true,
        autoReplyContent: "Away"
    )
    private let recipients = [ScheduledAbsenceRecipient(email: "a@x.com", name: "Alice")]

    private func message(uid: String, body content: String?) -> Message {
        let message = Message()
        message.uid = uid
        if let content {
            let body = Body()
            body.type = .textPlain
            body.value = content
            message.body = body
        }
        return message
    }

    private func viewModelWithOngoingAbsence(threadUid: String = "thread") -> ThreadScheduledAbsenceViewModel {
        let viewModel = ThreadScheduledAbsenceViewModel()
        viewModel.resetIfNeeded(threadUid: threadUid, recipients: recipients)
        viewModel.update(absencesByEmail: ["a@x.com": [ongoing]], orderedEmails: ["a@x.com"], now: now)
        return viewModel
    }

    @Test func hidesActionWhenALoadedBodyIsTheAutoReply() async {
        let viewModel = viewModelWithOngoingAbsence()

        await viewModel.hideActionIfAutoReplyIsDisplayed(in: [message(uid: "1", body: "Hello"), message(uid: "2", body: nil)])
        #expect(viewModel.isAutoReplyAlreadyDisplayed == false)

        await viewModel.hideActionIfAutoReplyIsDisplayed(in: [message(uid: "1", body: "Hello"), message(uid: "2", body: " away ")])
        #expect(viewModel.isAutoReplyAlreadyDisplayed == true)
    }

    @Test func doesNotCheckAlreadyCheckedMessagesAgain() async {
        let viewModel = viewModelWithOngoingAbsence()

        await viewModel.hideActionIfAutoReplyIsDisplayed(in: [message(uid: "1", body: "Hello")])
        // Same uid: the body was already compared and is not checked again.
        await viewModel.hideActionIfAutoReplyIsDisplayed(in: [message(uid: "1", body: "Away")])
        #expect(viewModel.isAutoReplyAlreadyDisplayed == false)
    }

    @Test func refetchingTheSameAbsenceKeepsTheActionHidden() async {
        let viewModel = viewModelWithOngoingAbsence()
        await viewModel.hideActionIfAutoReplyIsDisplayed(in: [message(uid: "1", body: "Away")])

        viewModel.resetIfNeeded(threadUid: "thread", recipients: recipients)
        viewModel.update(absencesByEmail: ["a@x.com": [ongoing]], orderedEmails: ["a@x.com"], now: now)

        #expect(viewModel.isAutoReplyAlreadyDisplayed == true)
    }

    @Test func switchingThreadResetsTheState() async {
        let viewModel = viewModelWithOngoingAbsence(threadUid: "thread1")
        await viewModel.hideActionIfAutoReplyIsDisplayed(in: [message(uid: "1", body: "Away")])

        viewModel.resetIfNeeded(threadUid: "thread2", recipients: recipients)
        #expect(viewModel.summary == nil)
        #expect(viewModel.descriptionsByEmail.isEmpty)

        viewModel.update(absencesByEmail: ["a@x.com": [ongoing]], orderedEmails: ["a@x.com"], now: now)
        #expect(viewModel.isAutoReplyAlreadyDisplayed == false)
    }
}
