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

import CocoaLumberjackSwift
import Foundation
import InfomaniakCore
import RealmSwift
import Sentry

public class MailboxManager {
    public class MailboxManagerConstants {
        private let fileManager = FileManager.default
        public let rootDocumentsURL: URL
        public let groupDirectoryURL: URL
        public let cacheDirectoryURL: URL

        init() {
            groupDirectoryURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AccountManager.appGroup)!
            rootDocumentsURL = groupDirectoryURL.appendingPathComponent("mailboxes", isDirectory: true)
            cacheDirectoryURL = groupDirectoryURL.appendingPathComponent("Library/Caches", isDirectory: true)
            print(groupDirectoryURL)
            try? fileManager.setAttributes(
                [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: groupDirectoryURL.path
            )
            try? FileManager.default.createDirectory(
                atPath: rootDocumentsURL.path,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try? FileManager.default.createDirectory(
                atPath: cacheDirectoryURL.path,
                withIntermediateDirectories: true,
                attributes: nil
            )

            DDLogInfo(
                "App working path is: \(fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.absoluteString ?? "")"
            )
            DDLogInfo("Group container path is: \(groupDirectoryURL.absoluteString)")
        }
    }

    public static let constants = MailboxManagerConstants()

    public var realmConfiguration: Realm.Configuration
    public var mailbox: Mailbox
    public private(set) var apiFetcher: MailApiFetcher

    init(mailbox: Mailbox, apiFetcher: MailApiFetcher) {
        self.mailbox = mailbox
        self.apiFetcher = apiFetcher
        let realmName = "\(mailbox.userId)-\(mailbox.mailboxId).realm"
        realmConfiguration = Realm.Configuration(
            fileURL: MailboxManager.constants.rootDocumentsURL.appendingPathComponent(realmName),
            schemaVersion: 1,
            objectTypes: [Folder.self, Thread.self, Message.self, Recipient.self]
        )
    }

    public func getRealm() -> Realm {
        do {
            return try Realm(configuration: realmConfiguration)
        } catch {
            // We can't recover from this error but at least we report it correctly on Sentry
            Logging.reportRealmOpeningError(error, realmConfiguration: realmConfiguration)
        }
    }

    // MARK: - Folders

    public func folders() async throws {
        // Get from realm
        guard ReachabilityListener.instance.currentStatus != .offline else {
            return
        }
        // Get from API
        let folderResult = try await apiFetcher.folders(mailbox: mailbox)

        let realm = getRealm()

        // Update folders in Realm
        try? realm.safeWrite {
            realm.add(folderResult, update: .modified)
        }
    }

    // MARK: - Thread

    public func threads(folder: Folder, filter: Filter = .all) async throws {
        // Get from realm
        guard ReachabilityListener.instance.currentStatus != .offline else {
            return
        }
        // Get from API
        let threadResult = try await apiFetcher.threads(mailbox: mailbox, folder: folder, filter: filter)

        let realm = getRealm()

        // Update thread in Realm
        try? realm.safeWrite {
            realm.add(threadResult.threads ?? [], update: .modified)
            realm.object(ofType: Folder.self, forPrimaryKey: folder.id)?.threads.insert(objectsIn: threadResult.threads ?? [])
        }
    }

    // MARK: - Utilities
}

public extension Realm {
    func safeWrite(_ block: () throws -> Void) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }
}

