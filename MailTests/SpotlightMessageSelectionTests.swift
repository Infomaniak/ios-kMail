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
import RealmSwift
import Testing

@Suite
struct SpotlightMessageSelectionTests {
    @Test("Empty mailboxes leave the selection empty")
    func emptyMailboxes() throws {
        var selection = SpotlightMessageSelection()

        try merge([], mailboxId: "empty", into: &selection)

        #expect(selection.candidates.isEmpty)
    }

    @Test("All messages are retained below the global limit")
    func keepsAllMessagesWhenBelowLimit() throws {
        var selection = SpotlightMessageSelection()
        try merge([3, 1], mailboxId: "first", into: &selection)
        try merge([], mailboxId: "empty", into: &selection)
        try merge([2, 0], mailboxId: "second", into: &selection)

        #expect(selection.candidates.map(\.date) == [3, 2, 1, 0].map(date))
        #expect(selection.candidates.map(\.mailboxId) == ["first", "second", "first", "second"])
    }

    @Test("A single mailbox contributes at most its 100 newest messages")
    func singleMailboxIsLimitedTo100NewestMessages() throws {
        var selection = SpotlightMessageSelection()
        try merge(Array(0 ..< 250), mailboxId: "first", into: &selection)

        #expect(SpotlightIndexer.maxIndexedMessages == 100)
        #expect(selection.candidates.count == 100)
        #expect(selection.candidates.map(\.date) == (150 ..< 250).reversed().map(date))
    }

    @Test("Interleaved mailbox messages share one global limit")
    func mergesInterleavedMessagesWithAGlobalLimit() throws {
        var selection = SpotlightMessageSelection()
        try merge(Array(stride(from: 0, to: 300, by: 2)), mailboxId: "even", into: &selection)
        try merge(Array(stride(from: 1, to: 300, by: 2)), mailboxId: "odd", into: &selection)

        #expect(selection.candidates.count == 100)
        #expect(selection.candidates.map(\.date) == (200 ..< 300).reversed().map(date))
        #expect(selection.candidates.filter { $0.mailboxId == "even" }.count == 50)
        #expect(selection.candidates.filter { $0.mailboxId == "odd" }.count == 50)
    }

    @Test("Older and empty mailboxes do not displace selected messages")
    func olderAndEmptyMailboxesDoNotDisplaceWinners() throws {
        var selection = SpotlightMessageSelection()
        try merge(Array(100 ..< 200), mailboxId: "newest", into: &selection)
        let expected = selection.candidates

        try merge(Array(0 ..< 100), mailboxId: "older", into: &selection)
        try merge([], mailboxId: "empty", into: &selection)

        #expect(selection.candidates == expected)
    }

    @Test("A newer mailbox can replace every selected message")
    func newerMailboxCanReplaceEveryWinner() throws {
        var selection = SpotlightMessageSelection()
        try merge(Array(0 ..< 100), mailboxId: "older", into: &selection)
        try merge(Array(100 ..< 250), mailboxId: "newest", into: &selection)

        #expect(selection.candidates.map(\.date) == (150 ..< 250).reversed().map(date))
        #expect(selection.candidates.allSatisfy { $0.mailboxId == "newest" })
    }

    @Test("Equal dates retain candidates from earlier mailboxes")
    func equalDatesKeepCandidatesFromEarlierMailboxes() throws {
        var forward = SpotlightMessageSelection()
        var reverse = SpotlightMessageSelection()
        let timestamps = Array(repeating: 42, count: 150)

        for mailboxId in ["a", "b"] {
            try merge(timestamps, mailboxId: mailboxId, into: &forward)
        }
        for mailboxId in ["b", "a"] {
            try merge(timestamps, mailboxId: mailboxId, into: &reverse)
        }

        #expect(forward.candidates.count == 100)
        #expect(reverse.candidates.count == 100)
        #expect(forward.candidates.allSatisfy { $0.mailboxId == "a" })
        #expect(reverse.candidates.allSatisfy { $0.mailboxId == "b" })
        #expect(forward.candidates.map(\.date) == reverse.candidates.map(\.date))
    }

    @Test("An equal date at the cutoff does not displace the oldest candidate")
    func equalDateAtCutoffDoesNotDisplaceOldestCandidate() throws {
        var selection = SpotlightMessageSelection()
        try merge(Array(0 ..< 100), mailboxId: "b", into: &selection)
        try merge([0, -1], mailboxId: "a", into: &selection)

        #expect(selection.candidates.count == 100)
        #expect(selection.candidates.last?.mailboxId == "b")
        #expect(selection.candidates.map(\.date) == (0 ..< 100).reversed().map(date))
    }

    @Test("Equal-date candidates are not ordered by identifiers")
    func equalDateCandidatesAreNotOrderedByIdentifiers() {
        let first = SpotlightMessageSelection.Candidate(mailboxId: "a", messageId: "1", date: date(42))
        let second = SpotlightMessageSelection.Candidate(mailboxId: "b", messageId: "2", date: date(42))
        let sameMailbox = SpotlightMessageSelection.Candidate(mailboxId: "a", messageId: "2", date: date(42))

        #expect(!first.isOrderedBefore(second))
        #expect(!second.isOrderedBefore(first))
        #expect(!first.isOrderedBefore(sameMailbox))
        #expect(!sameMailbox.isOrderedBefore(first))
    }

    @Test("More than ten mailboxes remain bounded after every merge")
    func visitsMoreThanTenMailboxesAndRemainsBoundedAfterEveryMerge() throws {
        var selection = SpotlightMessageSelection()

        for mailbox in 0 ..< 15 {
            let start = mailbox * 25
            try merge(Array(start ..< start + 25), mailboxId: String(mailbox), into: &selection)
            #expect(selection.candidates.count == min(start + 25, 100))
        }

        #expect(selection.candidates.map(\.date) == (275 ..< 375).reversed().map(date))
        #expect(selection.candidates.first?.mailboxId == "14")
    }

    private func merge(_ timestamps: [Int], mailboxId: String, into selection: inout SpotlightMessageSelection) throws {
        let realm = InMemoryRealmAccessor().getRealm()
        try realm.write {
            for (index, timestamp) in timestamps.enumerated().reversed() {
                let message = Message()
                message.uid = String(index)
                message.date = date(timestamp)
                realm.add(message)
            }
        }

        selection.merge(realm.objects(Message.self), mailboxId: mailboxId)
    }

    private func date(_ timestamp: Int) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}
