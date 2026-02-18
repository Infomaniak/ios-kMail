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

    func testMailboxes() async throws {
        let mailboxes = try await currentApiFetcher.mailboxes()
        XCTAssertTrue(!mailboxes.isEmpty)
    }

    func testFolders() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        XCTAssertTrue(!folders.isEmpty)
    }

    func testThreads() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let inboxFolder = folders.first { $0.role == .inbox }!
        let threadResult = try await currentApiFetcher.threads(mailbox: mailbox, folderId: inboxFolder.remoteId)
        XCTAssertTrue(!threadResult.threads!.isEmpty)
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
        let quotas = try await currentApiFetcher.quotas(mailbox: mailbox)
        XCTAssertTrue(quotas.size >= 0)
    }

    func testExternalMailFlag() async throws {
        let mailbox = try await setUpTest()
        _ = try await currentApiFetcher.externalMailFlag(mailbox: mailbox)
    }

    // MARK: - Common API Tests

    func testCheckAPIStatus() async throws {
        _ = try await currentApiFetcher.checkAPIStatus()
    }

    func testThreadsFromResource() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let inboxFolder = folders.first { $0.role == .inbox }!
        let threadResult = try await currentApiFetcher.threads(mailbox: mailbox, folderId: inboxFolder.remoteId)
        guard let resource = threadResult.resourceNext else { return }
        _ = try await currentApiFetcher.threads(from: resource, searchFilter: [])
    }

    // MARK: - Extended API Tests

    func testPermissions() async throws {
        let mailbox = try await setUpTest()
        _ = try await currentApiFetcher.permissions(mailbox: mailbox)
    }

    func testSendersRestrictions() async throws {
        let mailbox = try await setUpTest()
        let restrictions = try await currentApiFetcher.sendersRestrictions(mailbox: mailbox)
        XCTAssertNotNil(restrictions)
    }

    func testFeatureFlag() async throws {
        let mailbox = try await setUpTest()
        _ = try await currentApiFetcher.featureFlag(mailbox.uuid)
    }

    func testContacts() async throws {
        let contacts = try await currentApiFetcher.contacts()
        XCTAssertTrue(!contacts.isEmpty)
    }

    func testAddressBooks() async throws {
        let addressBookResults = try await currentApiFetcher.addressBooks()
        XCTAssertTrue(!addressBookResults.addressBooks.isEmpty)
    }

    func testSignatures() async throws {
        let mailbox = try await setUpTest()
        let signatureResponse = try await currentApiFetcher.signatures(mailbox: mailbox)
        XCTAssertTrue(!signatureResponse.signatures.isEmpty)
    }

    func testFlushFolder() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        guard let trashFolder = folders.first(where: { $0.role == .trash }) else { return }
        _ = try await currentApiFetcher.flushFolder(mailbox: mailbox, folderId: trashFolder.remoteId)
    }

    func testMessagesUids() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let inboxFolder = folders.first { $0.role == .inbox }!
        let uidsResult = try await currentApiFetcher.messagesUids(mailboxUuid: mailbox.uuid, folderId: inboxFolder.remoteId)
        XCTAssertTrue(!uidsResult.messageShortUids.isEmpty)
    }

    func testMessagesByUids() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let inboxFolder = folders.first { $0.role == .inbox }!
        let uidsResult = try await currentApiFetcher.messagesUids(mailboxUuid: mailbox.uuid, folderId: inboxFolder.remoteId)
        guard !uidsResult.messageShortUids.isEmpty else { return }
        let messagesResult = try await currentApiFetcher.messagesByUids(
            mailboxUuid: mailbox.uuid,
            folderId: inboxFolder.remoteId,
            messageUids: Array(uidsResult.messageShortUids.prefix(10))
        )
        XCTAssertTrue(!messagesResult.messages.isEmpty)
    }

    func testMessagesDelta() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let inboxFolder = folders.first { $0.role == .inbox }!
        let uidsResult = try await currentApiFetcher.messagesUids(mailboxUuid: mailbox.uuid, folderId: inboxFolder.remoteId)
        let delta = try await currentApiFetcher.messagesDelta(
            mailboxUuid: mailbox.uuid,
            folderId: inboxFolder.remoteId,
            signature: uidsResult.cursor,
            uids: nil
        ) as MessagesDelta<MessageFlags>
    }

    // MARK: - Attachment API Tests

    func testDownloadAttachments() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let inbox = folders.first { $0.role == .inbox }!
        let threadResult = try await currentApiFetcher.threads(mailbox: mailbox, folderId: inbox.remoteId)
        guard let threads = threadResult.threads, !threads.isEmpty else { return }
        let thread = threads[0]
        let messages = thread.messages
        guard !messages.isEmpty else { return }
        let message = messages[0]
        _ = try? await currentApiFetcher.downloadAttachments(message: message, progressObserver: nil)
    }

    // MARK: - Message Action Tests (Safe: only mark as seen/unseen)

    func testMarkAsSeenAndUnseen() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let inbox = folders.first { $0.role == .inbox }!
        let threadResult = try await currentApiFetcher.threads(mailbox: mailbox, folderId: inbox.remoteId)
        guard let threads = threadResult.threads, !threads.isEmpty else { return }
        let thread = threads[0]
        let messages = thread.messages
        guard !messages.isEmpty else { return }
        let message = messages[0]
        _ = try await currentApiFetcher.markAsSeen(mailbox: mailbox, messages: [message])
        _ = try await currentApiFetcher.markAsUnseen(mailbox: mailbox, messages: [message])
    }

    // MARK: - Draft API Tests

    func testDraftFromMessage() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let inbox = folders.first { $0.role == .inbox }!
        let threadResult = try await currentApiFetcher.threads(mailbox: mailbox, folderId: inbox.remoteId)
        guard let threads = threadResult.threads, !threads.isEmpty else { return }
        let thread = threads[0]
        let messages = thread.messages
        guard !messages.isEmpty else { return }
        let message = messages[0]
        guard message.draftResource != nil else { return }
        _ = try? await currentApiFetcher.draft(from: message)
    }

    func testDraftFromResource() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let draftFolder = folders.first { $0.role == .draft }
        guard let drafts = draftFolder else { return }
        let threadResult = try await currentApiFetcher.threads(mailbox: mailbox, folderId: drafts.remoteId, isDraftFolder: true)
        guard let threads = threadResult.threads, !threads.isEmpty else { return }
        let thread = threads[0]
        let messages = thread.messages
        guard !messages.isEmpty else { return }
        let message = messages[0]
        guard let draftResource = message.draftResource else { return }
        _ = try? await currentApiFetcher.draft(draftResource: draftResource)
    }

    // MARK: - Snooze API Tests

    func testSnoozeSettings() async throws {
        let mailbox = try await setUpTest()
        let folders = try await currentApiFetcher.folders(mailbox: mailbox)
        let inbox = folders.first { $0.role == .inbox }!
        let threadResult = try await currentApiFetcher.threads(mailbox: mailbox, folderId: inbox.remoteId)
        guard let threads = threadResult.threads, !threads.isEmpty else { return }
        let thread = threads[0]
        let messages = thread.messages
        guard !messages.isEmpty else { return }
        let message = messages[0]
        let snoozeDate = Date().addingTimeInterval(3600)
        _ = try? await currentApiFetcher.snooze(messages: [message], until: snoozeDate, mailbox: mailbox)
        if message.snoozeUuid != nil {
            _ = try? await currentApiFetcher.deleteSnooze(messages: [message], mailbox: mailbox)
        }
    }

    // MARK: - Other Tests

    func testMailHosted() async throws {
        let result = try await currentApiFetcher.mailHosted(for: ["test@example.com"])
        XCTAssertNotNil(result.first)
        XCTAssertFalse(result.first!.isInfomaniakHosted)
    }
}
