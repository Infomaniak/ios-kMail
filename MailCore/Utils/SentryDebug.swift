/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import RealmSwift
import Sentry

public enum SentryDebug {
    public static let knownDebugDate = Date(timeIntervalSince1970: 1_893_456_000)
    static func sendMissingMessagesSentry(sentUids: [String], receivedMessages: [Message], folder: Folder, newCursor: String?) {
        if receivedMessages.count != sentUids.count {
            let receivedUids = Set(receivedMessages.map { Constants.shortUid(from: $0.uid) })
            let missingUids = sentUids.filter { !receivedUids.contains($0) }
            if !missingUids.isEmpty {
                SentrySDK.capture(message: "We tried to download some Messages, but they were nowhere to be found") { scope in
                    scope.setLevel(.error)
                    scope.setContext(
                        value: ["uids": "\(missingUids.map { Constants.longUid(from: $0, folderId: folder.id) })",
                                "previousCursor": folder.cursor ?? "No cursor",
                                "newCursor": newCursor ?? "No cursor"],
                        key: "missingMessages"
                    )
                }
            }
        }
    }

    static func searchForOrphanMessages(
        folderId: String,
        using realm: Realm,
        previousCursor: String?,
        newCursor: String?
    ) {
        let realm = realm
        let orphanMessages = realm.objects(Message.self).where { $0.folderId == folderId }
            .filter { $0.threads.isEmpty && $0.threadsDuplicatedIn.isEmpty }
        if !orphanMessages.isEmpty {
            SentrySDK.capture(message: "We found some orphan Messages.") { scope in
                scope.setLevel(.error)
                scope.setContext(value: ["uids": "\(orphanMessages.map(\.uid).toArray())",
                                         "previousCursor": previousCursor ?? "No cursor",
                                         "newCursor": newCursor ?? "No cursor"],
                                 key: "orphanMessages")
            }
        }
    }

    static func searchForOrphanThreads(using realm: Realm, previousCursor: String?, newCursor: String?) {
        let realm = realm
        let orphanThreads = realm.objects(Thread.self).filter { $0.folder == nil }
        if !orphanThreads.isEmpty {
            SentrySDK.capture(message: "We found some orphan Threads.") { scope in
                scope.setLevel(.error)
                scope.setContext(value: ["uids": "\(orphanThreads.map(\.uid).toArray())",
                                         "previousCursor": previousCursor ?? "No cursor",
                                         "newCursor": newCursor ?? "No cursor"],
                                 key: "orphanThreads")
            }
        }
    }

    static func threadHasNilLastMessageFromFolderDate(thread: Thread) {
        SentrySDK.capture(message: "Thread has nil lastMessageFromFolderDate") { scope in
            scope.setContext(value: ["dates": "\(thread.messages.map(\.date))",
                                     "ids": "\(thread.messages.map(\.id))"],
                             key: "all messages")
            scope.setContext(value: ["id": "\(thread.lastMessageFromFolder?.uid ?? "nil")"],
                             key: "lastMessageFromFolder")
            scope.setContext(value: ["date before error": thread.date], key: "thread")
        }
    }

    static func createBreadcrumb(level: SentryLevel,
                                 category: String,
                                 message: String,
                                 data: [String: Any]? = nil) -> Breadcrumb {
        let crumb = Breadcrumb(level: level, category: category)
        crumb.type = level == .info ? "info" : "error"
        crumb.message = message
        crumb.data = data
        return crumb
    }

    static func captureWrongDate(step: String, startDate: Date, folder: Folder, alreadyWrongIds: [String], realm: Realm) -> Bool {
        guard let freshFolder = folder.fresh(using: realm) else { return false }

        let threads = freshFolder.threads
            .where { $0.date > startDate }
            .filter { !alreadyWrongIds.contains($0.uid) }
            .filter {
                !$0.messages.map(\.date).contains($0.date)
            }
        guard !threads.isEmpty else { return false }

        SentrySDK.capture(message: "No corresponding message date for thread on step \(step)") { scope in
            scope.setLevel(.error)
            scope.setContext(value: ["threads": Array(threads).map {
                [
                    "uid": "\($0.uid)",
                    "subject": $0.subject ?? "No subject",
                    "messageIds": "\($0.messageIds.joined(separator: ","))",
                    "lastMessageFromFolder": $0.lastMessageFromFolder?.uid ?? "nil",
                    "messages": Array($0.messages)
                        .map { ["message uid": $0.uid, "message subject": $0.subject ?? "No subject", "message date": $0.date] }
                ]
            }],
            key: "threads")
        }
        return true
    }
}
