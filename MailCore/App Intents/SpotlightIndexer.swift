/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import Algorithms
import CoreSpotlight
import Foundation
import InfomaniakDI
import OSLog
import RealmSwift

public final class SpotlightIndexer {
    private static let logger = Logger(category: "SpotlightIndexer")

    public static let spotlightIndexName = "Infomaniak Mail"
    public static let maxIndexedMessages = 100
    public static let shared = SpotlightIndexer()

    private static let indexingBatchSize = 10

    private let operationQueue = SpotlightIndexOperationQueue()

    private init() {}

    public func indexAllMessages() {
        guard #available(iOS 18.4, *) else {
            return
        }

        Task {
            do {
                try await reindexAllMessages()
            } catch {
                Self.logger.error("Failed to update the Spotlight index: \(error)")
            }
        }
    }

    @available(iOS 18.4, *)
    func reindexAllMessages() async throws {
        try await operationQueue.perform {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            let date = Date()
            var selection = SpotlightMessageSelection()
            for mailbox in mailboxInfosManager.getMailboxes() where !mailbox.isLocked {
                try Task.checkCancellation()
                autoreleasepool {
                    guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                        Self.logger.warning("Skipping Spotlight indexing for an unavailable mailbox")
                        return
                    }

                    let messages = mailboxManager.fetchResults(ofType: Message.self) { $0 }
                    selection.merge(messages, mailboxId: mailbox.objectId)
                }
            }

            try Task.checkCancellation()
            let searchableIndex = CSSearchableIndex(name: Self.spotlightIndexName)
            try await searchableIndex.deleteAppEntities(ofType: MailMessageEntity.self)

            for batch in selection.candidates.chunks(ofCount: Self.indexingBatchSize) {
                try Task.checkCancellation()
                let entities = autoreleasepool {
                    batch.compactMap { candidate -> MailMessageEntity? in
                        guard let mailbox = mailboxInfosManager.getMailbox(objectId: candidate.mailboxId),
                              !mailbox.isLocked,
                              let mailboxManager = accountManager.getMailboxManager(for: mailbox),
                              let message = mailboxManager.fetchObject(
                                  ofType: Message.self,
                                  forPrimaryKey: candidate.messageId
                              ) else {
                            Self.logger.debug("Skipping a Spotlight candidate that is no longer available")
                            return nil
                        }

                        return MailMessageEntity(message: message, mailbox: mailbox)
                    }
                }

                if !entities.isEmpty {
                    try await searchableIndex.indexAppEntities(entities)
                }
            }

            Self.logger.info("Spotlight updated in \(Date().timeIntervalSince(date)) seconds")
        }
    }

    public func deindexMessagesForMailbox(ids: [String]) {
        Task {
            do {
                try await operationQueue.perform {
                    try await CSSearchableIndex(name: Self.spotlightIndexName).deleteSearchableItems(withDomainIdentifiers: ids)
                }
            } catch {
                Self.logger.error("Failed to remove a mailbox from Spotlight: \(error)")
            }
        }
    }

    public func deindexAllMessages() {
        guard #available(iOS 18.4, *) else {
            return
        }

        Task {
            do {
                try await operationQueue.perform {
                    try await CSSearchableIndex(name: Self.spotlightIndexName).deleteAppEntities(ofType: MailMessageEntity.self)
                }
            } catch {
                Self.logger.error("Failed to clear the Spotlight index: \(error)")
            }
        }
    }
}

struct SpotlightMessageSelection {
    struct Candidate: Equatable {
        let mailboxId: String
        let messageId: String
        let date: Date

        func isOrderedBefore(_ other: Candidate) -> Bool {
            return date > other.date
        }
    }

    private(set) var candidates: [Candidate] = []

    mutating func merge(_ messages: Results<Message>, mailboxId: String) {
        let limit = SpotlightIndexer.maxIndexedMessages
        var eligibleMessages = messages
        if candidates.count == limit, let cutoff = candidates.last?.date {
            eligibleMessages = eligibleMessages.where { $0.date > cutoff }
        }

        let sortedMessages = eligibleMessages.sorted(by: \.date, ascending: false)
        var iterator = sortedMessages.lazy.prefix(limit).map {
            Candidate(mailboxId: mailboxId, messageId: $0.uid, date: $0.date)
        }.makeIterator()
        var nextCandidate = iterator.next()
        var currentIndex = 0
        var merged: [Candidate] = []
        merged.reserveCapacity(limit)

        while merged.count < limit {
            if let candidate = nextCandidate,
               currentIndex == candidates.count || candidate.isOrderedBefore(candidates[currentIndex]) {
                merged.append(candidate)
                if merged.count < limit {
                    nextCandidate = iterator.next()
                }
            } else if currentIndex < candidates.count {
                merged.append(candidates[currentIndex])
                currentIndex += 1
            } else {
                break
            }
        }

        candidates = merged
    }
}

private actor SpotlightIndexOperationQueue {
    private var pendingOperation: Task<Void, Error>?

    func perform(_ operation: @escaping @Sendable () async throws -> Void) async throws {
        let previousOperation = pendingOperation
        let operationTask = Task {
            // A previous failure is reported to its caller and must not block subsequent operations.
            _ = try? await previousOperation?.value
            try Task.checkCancellation()
            try await operation()
        }
        pendingOperation = operationTask
        try await withTaskCancellationHandler {
            try await operationTask.value
        } onCancel: {
            operationTask.cancel()
        }
    }
}
