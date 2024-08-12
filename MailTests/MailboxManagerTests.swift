/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import InfomaniakDI
import InfomaniakLogin
@testable import MailCore
import XCTest

final class MailboxManagerTests: XCTestCase {
    static var mailboxManager: MailboxManager!

    override class func setUp() {
        super.setUp()

        MockingHelper.clearRegisteredTypes()

        let accountManager = AccountManager()
        let accountManagerFactory = Factory(type: AccountManager.self) { _, _ in
            accountManager
        }

        MockingHelper.registerConcreteTypes(configuration: .realApp, extraFactories: [accountManagerFactory])

        MailboxManagerTests.mailboxManager = MockingHelper.getTestMailboxManager()
    }

    override func setUp() {
        do {
            try MailboxManagerTests.mailboxManager.writeTransaction { realm in
                realm.deleteAll()
            }
        } catch {
            fatalError("Could't cleanup realm before tests\(error)")
        }
    }

    // MARK: Tests methods

    func testFolders() async throws {
        // GIVEN

        // WHEN
        let missingInboxFolder = MailboxManagerTests.mailboxManager.getFolder(with: .inbox)
        try await MailboxManagerTests.mailboxManager.refreshAllFolders()
        let inboxFolder = MailboxManagerTests.mailboxManager.getFolder(with: .inbox)

        // THEN
        XCTAssertNil(missingInboxFolder, "Inbox shouldn't exist before fetch")
        XCTAssertNotNil(inboxFolder, "Inbox should exist after fetch")
    }

    func testThreads() async throws {
        // GIVEN
        try await MailboxManagerTests.mailboxManager.refreshAllFolders()
        let inboxFolder = MailboxManagerTests.mailboxManager.getFolder(with: .inbox)!
        let previousUpdateDate = inboxFolder.lastUpdate

        // WHEN
        try await MailboxManagerTests.mailboxManager.threads(folder: inboxFolder.freezeIfNeeded())
        let inboxFolderAfterFetch = MailboxManagerTests.mailboxManager.getFolder(with: .inbox)!
        let currentUpdateDate = inboxFolderAfterFetch.lastUpdate

        // THEN
        XCTAssertNotEqual(previousUpdateDate, currentUpdateDate, "lastUpdate dates should be different")
    }

    func testMessage() async throws {
        // GIVEN
        let folders = try await MailboxManagerTests.mailboxManager.apiFetcher
            .folders(mailbox: MailboxManagerTests.mailboxManager.mailbox)
        let threadResult = try await MailboxManagerTests.mailboxManager.apiFetcher.threads(
            mailbox: MailboxManagerTests.mailboxManager.mailbox,
            folderId: folders[0].remoteId
        )

        // WHEN
        let messageBeforeDownload = threadResult.threads![0].messages[0]
        try await MailboxManagerTests.mailboxManager.message(message: threadResult.threads![0].messages[0])
        let messageAfterDownload = MailboxManagerTests.mailboxManager.transactionExecutor.fetchObject(
            ofType: Message.self,
            forPrimaryKey: messageBeforeDownload.uid
        )

        // THEN
        XCTAssertFalse(messageBeforeDownload.fullyDownloaded, "Message shouldn't be downloaded right after fetch")
        XCTAssertNotNil(messageAfterDownload, "Complete Message should exist in database")
        XCTAssertTrue(messageAfterDownload?.fullyDownloaded == true, "Complete Message should be fully downloaded")
    }
}
