//
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
import InfomaniakLogin
import XCTest

@testable import MailCore

final class MailboxManagerTests: XCTestCase {
    static var mailboxManager: MailboxManager!

    override class func setUp() {
        super.setUp()
        mailboxManager = AccountManager.instance.getMailboxManager(for: Env.mailboxId, userId: Env.userId)

        let token = ApiToken(accessToken: Env.token,
                             expiresIn: Int.max,
                             refreshToken: "",
                             scope: "",
                             tokenType: "",
                             userId: Env.userId,
                             expirationDate: Date(timeIntervalSinceNow: TimeInterval(Int.max)))
        mailboxManager.apiFetcher.setToken(token, delegate: FakeTokenDelegate())
    }

    // MARK: Tests methods

    func testFolders() async throws {
        try await MailboxManagerTests.mailboxManager.folders()
    }

    func testThreads() async throws {
        let folders = try await MailboxManagerTests.mailboxManager.apiFetcher.folders(mailbox: MailboxManagerTests.mailboxManager.mailbox)
        try await MailboxManagerTests.mailboxManager.threads(folder: folders[0], filter: .all)
    }

    func testMessage() async throws {
        let folders = try await MailboxManagerTests.mailboxManager.apiFetcher.folders(mailbox: MailboxManagerTests.mailboxManager.mailbox)
        let threadResult = try await MailboxManagerTests.mailboxManager.apiFetcher.threads(mailbox: MailboxManagerTests.mailboxManager.mailbox, folder: folders[0])
        try await MailboxManagerTests.mailboxManager.message(message: threadResult.threads![0].messages[0])
    }
}
