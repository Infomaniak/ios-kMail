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
import InfomaniakLogin
@testable import MailCore
import XCTest

final class MailApiTests: XCTestCase {
    override static func setUp() {
        super.setUp()

        MockingHelper.clearRegisteredTypes()
        MockingHelper.registerConcreteTypes(configuration: .realApp)
    }

    let currentApiFetcher: MailApiFetcher = {
        let token = ApiToken(accessToken: Env.token,
                             expiresIn: Int.max,
                             refreshToken: "",
                             scope: "",
                             tokenType: "",
                             userId: Env.userId,
                             expirationDate: Date(timeIntervalSinceNow: TimeInterval(Int.max)))
        return MailApiFetcher(token: token, delegate: MCKTokenDelegate())
    }()

    // MARK: - Tests setup

    func setUpTest() async throws -> Mailbox {
        let mailboxes = try await currentApiFetcher.mailboxes()
        XCTAssertTrue(!mailboxes.isEmpty)
        return mailboxes[0]
    }

    // MARK: - Tests methods

    func testFolders() async throws {
        let mailbox = try await setUpTest()
        _ = try await currentApiFetcher.folders(mailbox: mailbox)
    }

    func testThreads() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let inboxFolder = folders.first { $0.role == .inbox }!
        _ = try await currentApiFetcher.threads(mailbox: mailbox, folderId: inboxFolder.remoteId)
    }

    func testMessage() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let inbox = folders.first { $0.role == .inbox }!
        let threadResult = try await currentApiFetcher.threads(mailbox: mailbox, folderId: inbox.remoteId)
        _ = try await currentApiFetcher.message(message: threadResult.threads![0].messages[0])
    }

    func testQuotas() async throws {
        let mailbox = try await setUpTest()
        _ = try await currentApiFetcher.quotas(mailbox: mailbox)
    }

    func testExternalMailFlag() async throws {
        let mailbox = try await setUpTest()
        _ = try await currentApiFetcher.externalMailFlag(mailbox: mailbox)
    }
}
