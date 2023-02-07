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

struct SentryDebug {
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
            .filter { $0.parentThreads.isEmpty && $0.parentThreadsAsDuplicate.isEmpty }
        if !orphanMessages.isEmpty {
            SentrySDK.capture(message: "We found some orphan Messages.") { scope in
                scope.setLevel(.error)
                scope.setContext(value: ["uids": "\(orphanMessages.map { $0.uid })",
                                         "previousCursor": previousCursor ?? "No cursor",
                                         "newCursor": newCursor ?? "No cursor"],
                                 key: "orphanMessages")
            }
        }
    }

    static func searchForOrphanThreads(using realm: Realm, previousCursor: String?, newCursor: String?) {
        let realm = realm
        let orphanThreads = realm.objects(Thread.self).filter { $0.parentLink.isEmpty }
        if !orphanThreads.isEmpty {
            SentrySDK.capture(message: "We found some orphan Threads.") { scope in
                scope.setLevel(.error)
                scope.setContext(value: ["uids": "\(orphanThreads.map { $0.uid })",
                                         "previousCursor": previousCursor ?? "No cursor",
                                         "newCursor": newCursor ?? "No cursor"],
                                 key: "orphanThreads")
            }
        }
    }
}
