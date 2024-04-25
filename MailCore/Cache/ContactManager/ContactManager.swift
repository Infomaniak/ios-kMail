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
import Contacts
import Foundation
import InfomaniakCore
import InfomaniakCoreDB
import InfomaniakCoreUI
import RealmSwift
import SwiftRegex

/// The composite protocol of the `ContactManager` service
public typealias ContactManageable = ContactFetchable
    & ContactManagerCoreable
    & MailRealmAccessible
    & Transactionable

public protocol ContactManagerCoreable {
    func refreshContactsAndAddressBooksIfNeeded() async throws
    /// Entry point to refresh all contacts in base
    func refreshContactsAndAddressBooks() async throws

    /// Delete all contact data cache for user
    /// - Parameters:
    ///   - userId: User ID
    static func deleteUserContacts(userId: Int)
}

public final class ContactManager: ObservableObject, ContactManageable {
    public class ContactManagerConstants {
        private let fileManager = FileManager.default
        public let rootDocumentsURL: URL
        public let groupDirectoryURL: URL

        init() {
            groupDirectoryURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AccountManager.appGroup)!
            rootDocumentsURL = groupDirectoryURL.appendingPathComponent("contacts", isDirectory: true)

            try? FileManager.default.createDirectory(
                atPath: rootDocumentsURL.path,
                withIntermediateDirectories: true,
                attributes: nil
            )

            DDLogInfo(
                "App contacts working path is: \(fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.absoluteString ?? "")"
            )
            DDLogInfo("Group container path is: \(groupDirectoryURL.absoluteString)")
        }
    }

    public static let constants = ContactManagerConstants()

    public let realmConfiguration: Realm.Configuration
    private let backgroundRealm: BackgroundRealm
    public let transactionExecutor: Transactionable

    public lazy var viewRealm: Realm = {
        assert(Foundation.Thread.isMainThread, "viewRealm should only be accessed from main thread")
        return getRealm()
    }()

    let apiFetcher: MailApiFetcher

    public init(userId: Int, apiFetcher: MailApiFetcher) {
        self.apiFetcher = apiFetcher
        let realmName = "\(userId).realm"
        realmConfiguration = Realm.Configuration(
            fileURL: ContactManager.constants.rootDocumentsURL.appendingPathComponent(realmName),
            schemaVersion: 5,
            deleteRealmIfMigrationNeeded: true,
            objectTypes: [
                MergedContact.self,
                AddressBook.self
            ]
        )
        backgroundRealm = BackgroundRealm(configuration: realmConfiguration)
        transactionExecutor = TransactionExecutor(realmAccessible: backgroundRealm)

        excludeRealmFromBackup()
    }

    let localContactsHelper = LocalContactsHelper()
    var currentMergeRequest: Task<Void, Never>?
    var lastRefreshDate: Date?

    public func refreshContactsAndAddressBooksIfNeeded() async throws {
        let refreshIntervalSeconds = 60.0
        if let lastRefreshDate,
           lastRefreshDate.addingTimeInterval(refreshIntervalSeconds) > Date() {
            DDLogInfo("Skip updating contacts, we updated less than \(Int(refreshIntervalSeconds)) seconds ago")
            return
        }

        try await refreshContactsAndAddressBooks()
        lastRefreshDate = Date()
    }

    public func refreshContactsAndAddressBooks() async throws {
        // We do not run an update of contacts in extension mode as we are too resource constrained
        guard !Bundle.main.isExtension else {
            DDLogInfo("Skip updating contacts, we are in extension mode")
            return
        }

        do {
            // Track background refresh of addressBooks
            let backgroundTaskTracker = await ApplicationBackgroundTaskTracker(identifier: #function + UUID().uuidString)

            // Fetch remote content
            async let addressBooksRequest = apiFetcher.addressBooks().addressbooks

            // Process addressBooks
            let addressBooks = try await addressBooksRequest
            await backgroundRealm.execute { realm in
                try? realm.safeWrite {
                    realm.add(addressBooks, update: .modified)
                }
            }
            await backgroundTaskTracker.end()

            // Process Contacts
            await uniqueUpdateContactDBTask(apiFetcher)
        } catch {
            // Process Contacts anyway
            await uniqueUpdateContactDBTask(apiFetcher)

            throw error
        }
    }

    public static func deleteUserContacts(userId: Int) {
        let files = (try? FileManager.default
            .contentsOfDirectory(at: ContactManager.constants.rootDocumentsURL, includingPropertiesForKeys: nil))
        files?.forEach { file in
            if let matches = Regex(pattern: "(\\d+).realm.*")?.firstMatch(in: file.lastPathComponent), matches.count > 1 {
                let fileUserId = matches[1]
                if Int(fileUserId) == userId {
                    DDLogInfo("Deleting file: \(file.lastPathComponent)")
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
    }
}
