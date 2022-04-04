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

class FakeTokenDelegate: RefreshTokenDelegate {
    func didUpdateToken(newToken: ApiToken, oldToken: ApiToken) {}

    func didFailRefreshToken(_ token: ApiToken) {}
}

final class MailApiTests: XCTestCase {
    let currentApiFetcher: MailApiFetcher = {
        let token = ApiToken(accessToken: Env.token,
                             expiresIn: Int.max,
                             refreshToken: "",
                             scope: "",
                             tokenType: "",
                             userId: Env.userId,
                             expirationDate: Date(timeIntervalSinceNow: TimeInterval(Int.max)))
        return MailApiFetcher(token: token, delegate: FakeTokenDelegate())
    }()

    var mailboxes = [Mailbox]()

    // MARK: - Tests setup

    func setUpTest() async throws -> [Mailbox] {
        return try await currentApiFetcher.mailboxes()
    }

    // MARK: - Tests methods

    func testMailboxes() async throws {
        let mailboxes = try await setUpTest()
        XCTAssertTrue(!mailboxes.isEmpty)
    }

    func testFolders() async throws {
        let mailboxes = try await setUpTest()
        _ = try await currentApiFetcher.folders(mailbox: mailboxes[0])
    }

    func testThreads() async throws {
        let mailboxes = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailboxes[0])
        _ = try await currentApiFetcher.threads(mailbox: mailboxes[0], folder: folders[0])
    }

    func testMessage() async throws {
        let mailboxes = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailboxes[0])
        let threads = try await currentApiFetcher.threads(mailbox: mailboxes[0], folder: folders[0])
        let threadWithMessages = threads.threads?.first { $0.messagesCount > 0 }
        _ = try await currentApiFetcher.message(mailbox: mailboxes[0], message: threadWithMessages!.messages[0])
    }

    func testQuotas() async throws {
        let mailboxes = try await setUpTest()
        _ = try await currentApiFetcher.quotas(mailbox: mailboxes[0])
    }
}
