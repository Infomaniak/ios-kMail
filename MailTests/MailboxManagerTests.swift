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

    override func setUp() async throws {
        try await super.setUp()

        MockingHelper.clearRegisteredTypes()

        let accountManager = AccountManager()
        let accountManagerFactory = Factory(type: AccountManager.self) { _, _ in
            accountManager
        }

        MockingHelper.registerConcreteTypes(configuration: .realApp, extraFactories: [accountManagerFactory])

        MailboxManagerTests.mailboxManager = accountManager.getMailboxManager(for: Env.mailboxId, userId: Env.userId)

        let token = ApiToken(accessToken: Env.token,
                             expiresIn: Int.max,
                             refreshToken: "",
                             scope: "",
                             tokenType: "",
                             userId: Env.userId,
                             expirationDate: Date(timeIntervalSinceNow: TimeInterval(Int.max)))
        MailboxManagerTests.mailboxManager.apiFetcher.setToken(token, delegate: FakeTokenDelegate())
    }

    // MARK: Tests methods

    func testFolders() async throws {
        try await MailboxManagerTests.mailboxManager.refreshAllFolders()
    }

    func testThreads() async throws {
        let folders = try await MailboxManagerTests.mailboxManager.apiFetcher
            .folders(mailbox: MailboxManagerTests.mailboxManager.mailbox)
        try await MailboxManagerTests.mailboxManager.apiFetcher.threads(
            mailbox: MailboxManagerTests.mailboxManager.mailbox,
            folderId: folders[0].remoteId
        )
    }

    func testMessage() async throws {
        let folders = try await MailboxManagerTests.mailboxManager.apiFetcher
            .folders(mailbox: MailboxManagerTests.mailboxManager.mailbox)
        let threadResult = try await MailboxManagerTests.mailboxManager.apiFetcher.threads(
            mailbox: MailboxManagerTests.mailboxManager.mailbox,
            folderId: folders[0].remoteId
        )
        try await MailboxManagerTests.mailboxManager.message(message: threadResult.threads![0].messages[0])
    }
}
