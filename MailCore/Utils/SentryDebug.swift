/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import Alamofire
import Foundation
import InfomaniakCoreDB
import InfomaniakLogin
import RealmSwift
import Sentry

public enum SentryDebug {
    public static func setUserId(_ userId: Int) {
        guard userId != 0 else { return }
        let user = Sentry.User(userId: "\(userId)")
        user.ipAddress = "{{auto}}"
        SentrySDK.setUser(user)
    }

    // MARK: - Errors

    public static let knownDebugDate = Date(timeIntervalSince1970: 1_893_456_000)
    static func sendMissingMessagesSentry(sentUids: [String], receivedMessages: [Message], folder: Folder, newCursor: String?) {
        if receivedMessages.count != sentUids.count {
            let receivedUids = Set(receivedMessages.map { Constants.shortUid(from: $0.uid) })
            let missingUids = sentUids.filter { !receivedUids.contains($0) }
            if !missingUids.isEmpty {
                SentrySDK.capture(message: "We tried to download some Messages, but they were nowhere to be found") { scope in
                    scope.setLevel(.error)
                    scope.setContext(
                        value: ["uids": "\(missingUids.map { Constants.longUid(from: $0, folderId: folder.remoteId) })",
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

    static func captureWrongDate(
        step: String,
        startDate: Date,
        folder: Folder,
        alreadyWrongIds: [String],
        transactionable: Transactionable
    ) -> Bool {
        guard let freshFolder = folder.fresh(transactionable: transactionable) else { return false }

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
                    "messageIds": "\($0.messageIds.joined(separator: ","))",
                    "lastMessageFromFolder": $0.lastMessageFromFolder?.uid ?? "nil",
                    "messages": Array($0.messages)
                        .map { ["message uid": $0.uid, "message date": $0.date] }
                ]
            }],
            key: "threads")
        }
        return true
    }

    static func castToShortUidFailed(firstUid: String, secondUid: String) {
        SentrySDK.capture(message: "Failed casting to short Uid") { scope in
            scope.setLevel(.error)
            scope.setContext(
                value: ["firstUid": firstUid,
                        "secondUid": secondUid],
                key: "Uids"
            )
        }
    }

    static func messageHasInReplyTo(_ inReplyToList: [String]) {
        SentrySDK.capture(message: "Found an array of inReplyTo") { scope in
            scope.setContext(value: ["ids": inReplyToList.joined(separator: ", ")], key: "inReplyToList")
        }
    }

    public static func loginError(error: Error, step: String) {
        SentrySDK.capture(message: "Error while logging") { scope in
            scope.setLevel(.error)
            scope.setContext(
                value: ["step": step, "error": error, "description": error.localizedDescription],
                key: "underlying error"
            )
        }
    }

    public static func sendSubBodiesTrigger(messageUid: String) {
        SentrySDK.capture(message: "Received an email with SubBodies!!") { scope in
            scope.setLevel(.info)
            scope.setExtra(value: "messageUid", key: messageUid)
        }
    }

    // MARK: - Breadcrumb

    enum Category {
        static let ThreadAlgorithm = "Thread algo"
    }

    private static func createBreadcrumb(level: SentryLevel,
                                         category: String,
                                         message: String,
                                         data: [String: Any]? = nil) -> Breadcrumb {
        let crumb = Breadcrumb(level: level, category: category)
        crumb.type = level == .info ? "info" : "error"
        crumb.message = message
        crumb.data = data
        return crumb
    }

    private static func addAsyncBreadcrumb(level: SentryLevel,
                                           category: String,
                                           message: String,
                                           data: [String: Any]? = nil) {
        Task {
            let breadcrumb = createBreadcrumb(level: level, category: category, message: message, data: data)
            SentrySDK.addBreadcrumb(breadcrumb)
        }
    }

    static func nilDateParsingBreadcrumb(uid: String) {
        let breadcrumb = createBreadcrumb(level: .warning,
                                          category: Category.ThreadAlgorithm,
                                          message: "Nil message date decoded",
                                          data: ["uid": uid])
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    static func listIncoherentMessageUpdate(messages: [Message], actualSeen: Bool) {
        Task {
            for message in messages {
                guard let liveMessage = message.thaw(),
                      liveMessage.seen != actualSeen else { continue }

                SentrySDK.capture(message: "Found incoherent message update") { scope in
                    scope.setContext(value: ["Message": ["uid": message.uid,
                                                         "messageId": message.messageId ?? "nil",
                                                         "date": message.date,
                                                         "seen": message.seen,
                                                         "duplicates": message.duplicates.compactMap(\.messageId),
                                                         "references": message.references ?? "nil"],
                                             "Seen": ["Expected": actualSeen, "Actual": liveMessage.seen],
                                             "Folder": ["id": message.folder?.remoteId ?? "nil",
                                                        "name": message.folder?.matomoName ?? "nil",
                                                        "last update": message.folder?.lastUpdate as Any,
                                                        "cursor": message.folder?.cursor ?? "nil"]],
                                     key: "Message context")
                }
            }
        }
    }

    static func logTokenMigration(newToken: ApiToken, oldToken: ApiToken) {
        let newTokenIsInfinite = newToken.expirationDate == nil
        let oldTokenIsInfinite = oldToken.expirationDate == nil

        let additionalData = ["newTokenIsInfinite": newTokenIsInfinite, "oldTokenIsInfinite": oldTokenIsInfinite]
        let breadcrumb = Breadcrumb(level: .info, category: "Token")
        breadcrumb.message = "Token updated"
        breadcrumb.data = additionalData
        SentrySDK.addBreadcrumb(breadcrumb)

        // Only track migration
        guard newTokenIsInfinite else { return }

        SentrySDK.capture(message: "Update token infinite token") { scope in
            scope.setContext(value: additionalData,
                             key: "Migration context")
        }
    }

    static func addBackoffBreadcrumb(folder: Folder, index: Int) {
        let breadcrumb = Breadcrumb()
        breadcrumb.message = "Backoff \(index) for folder \(folder.matomoName) - \(folder.remoteId)"
        breadcrumb.level = .warning
        breadcrumb.type = "debug"
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    static func addResetingFolderBreadcrumb(folder: Folder) {
        let breadcrumb = Breadcrumb()
        breadcrumb.message = "Reseting folder after failed backoff \(folder.matomoName) - \(folder.remoteId)"
        breadcrumb.level = .warning
        breadcrumb.type = "debug"
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    static func failedResetingAfterBackoff(folder: Folder) {
        SentrySDK.capture(message: "Failed reseting folder after backoff") { scope in
            scope.setContext(value: ["Folder": ["Id": folder.id, "name": folder.matomoName]],
                             key: "Folder context")
        }
    }

    public static func filterChangedBreadcrumb(filterValue: String) {
        addAsyncBreadcrumb(
            level: .info,
            category: "ui",
            message: "Filter changed",
            data: ["value": filterValue]
        )
    }

    public static func switchMailboxBreadcrumb(mailboxObjectId: String) {
        addAsyncBreadcrumb(
            level: .info,
            category: "ui",
            message: "Mailbox changed",
            data: ["ObjectId": mailboxObjectId]
        )
    }

    public static func switchFolderBreadcrumb(uid: String, name: String) {
        addAsyncBreadcrumb(
            level: .info,
            category: "ui",
            message: "Mailbox changed",
            data: ["Uid": uid, "name": name]
        )
    }

    // MARK: - Standard log

    /// Process a local error  to Sentry for dashboard creation
    static func logInternalErrorToSentry(category: String, error: Error, function: String) {
        let metadata: [String: Any] = ["error": error, "localizedDescription": error.localizedDescription]

        // Add a breadcrumb
        let breadcrumb = Breadcrumb(level: .error, category: category)
        breadcrumb.message = "\(function)~>|\(error)"
        breadcrumb.data = metadata
        SentrySDK.addBreadcrumb(breadcrumb)

        // Only capture non cancel error
        guard shouldSendToSentry(error: error) else {
            return
        }

        // Add an error
        SentrySDK.capture(message: category) { scope in
            scope.setContext(value: metadata, key: "Internal Error Data")
        }
    }

    private static func shouldSendToSentry(error: Error) -> Bool {
        let possibleAfError = (error as? AFErrorWithContext)?.afError ?? error.asAFError

        if let possibleAfError {
            if possibleAfError.isExplicitlyCancelledError {
                return false
            } else if (possibleAfError.underlyingError as? NSError)?.code == NSURLErrorNotConnectedToInternet {
                return false
            } else {
                return true
            }
        } else if let wrappedAfError = (error as? AFErrorWithContext)?.afError {
            return shouldSendToSentry(error: wrappedAfError)
        } else if error is CancellationError {
            return false
        }

        return true
    }
}
