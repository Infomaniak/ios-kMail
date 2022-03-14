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
import InfomaniakCore
import RealmSwift

public class MailboxManager {
    public class MailboxManagerConstants {
        private let fileManager = FileManager.default
        public let rootDocumentsURL: URL
        public let groupDirectoryURL: URL

        init() {
            groupDirectoryURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AccountManager.appGroup)!
            rootDocumentsURL = groupDirectoryURL.appendingPathComponent("mailboxes", isDirectory: true)
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
            // Handle Error
            fatalError()
        }
    }

    // MARK: - Folders

    func getCachedFolders(freeze: Bool = true, using realm: Realm? = nil) -> [Folder]? {
        let realm = realm ?? getRealm()
        let folders = realm.objects(Folder.self).filter {
            $0.parent == nil
        }
        return freeze ? folders.map { $0.freeze() } : folders.map { $0 }
    }

    public func folders() async throws -> [Folder] {
        // Get from realm
        if let cachedFolders = getCachedFolders(freeze: false), ReachabilityListener.instance.currentStatus == .offline {
            return cachedFolders
        } else {
            // Get from API
            let folders = try await apiFetcher.folders(mailbox: mailbox)
            let realm = getRealm()

            // Update folders in Realm
            try? realm.safeWrite {
                realm.add(folders, update: .modified)
            }

            return folders.map { $0.freeze() }
        }
    }

    // MARK: - Thread

    func getCachedThreads(freeze: Bool = true, using realm: Realm? = nil) -> [Thread]? {
        let realm = realm ?? getRealm()
        let threads = realm.objects(Thread.self)
        return freeze ? threads.map { $0.freeze() } : threads.map { $0 }
    }

    public func threads(folder: Folder, filter: Filter = .all) async throws -> [Thread] {
        // Get from realm
        if let cachedThreads = getCachedThreads(freeze: false), ReachabilityListener.instance.currentStatus == .offline {
            return cachedThreads
        } else {
            // Get from API
            let threadResult = try await apiFetcher.threads(mailbox: mailbox, folder: folder, filter: filter)

            let realm = getRealm()

            // Update folders in Realm
            try? realm.safeWrite {
                realm.add(threadResult.threads ?? [], update: .modified)
            }

            return threadResult.threads?.map { $0.freeze() } ?? []
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
