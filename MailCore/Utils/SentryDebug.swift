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
import InfomaniakCore
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

    public static func captureNoTokenError(account: ApiToken?) {
        SentrySDK.capture(message: "Account with no token") { scope in
            scope.setLevel(.info)
            scope.setExtra(value: "account", key: "\(account?.userId ?? -1)")
        }
    }

    // MARK: - Breadcrumb

    public enum Category: String {
        case threadAlgorithm = "Thread algo"
        case syncedAuthenticator = "SyncedAuthenticator"
    }

    // periphery:ignore
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
            } else if [NSURLErrorNotConnectedToInternet, NSURLErrorTimedOut]
                .contains((possibleAfError.underlyingError as? NSError)?.code) {
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

// MARK: - SHARED -

public extension SentryDebug {
    static func addAsyncBreadcrumb(level: SentryLevel,
                                   category: String,
                                   message: String,
                                   data: [String: Any]? = nil) {
        Task {
            let breadcrumb = Breadcrumb(level: level, category: category)
            breadcrumb.message = message
            breadcrumb.data = data
            SentrySDK.addBreadcrumb(breadcrumb)
        }
    }

    static func asyncCapture(
        error: Error,
        context: [String: Any]? = nil,
        contextKey: String? = nil,
        extras: [String: Any]? = nil
    ) {
        Task {
            SentrySDK.capture(error: error) { scope in
                if let context, let contextKey {
                    scope.setContext(value: context, key: contextKey)
                }

                if let extras {
                    scope.setExtras(extras)
                }
            }
        }
    }

    static func asyncCapture(
        message: String,
        context: [String: Any]? = nil,
        contextKey: String? = nil,
        level: SentryLevel? = nil,
        extras: [String: Any]? = nil
    ) {
        Task {
            SentrySDK.capture(message: message) { scope in
                if let context, let contextKey {
                    scope.setContext(value: context, key: contextKey)
                }

                if let level {
                    scope.setLevel(level)
                }

                if let extras {
                    scope.setExtras(extras)
                }
            }
        }
    }
}
