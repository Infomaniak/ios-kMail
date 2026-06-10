/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

@testable import Infomaniak_Mail
@testable import MailCore
import XCTest

final class NoReplyAlertTests: XCTestCase {
    let currentMailBoxEmail = "test@example.com"

    // MARK: - Helpers

    private func createMessage(from: [String], cc: [String] = []) -> Message {
        let message = Message()
        message.from = from.map { Recipient(email: $0, name: "") }.toRealmList()
        message.cc = cc.map { Recipient(email: $0, name: "") }.toRealmList()
        return message
    }

    // MARK: - Tests for isNoReply detection via verifySenders

    func testNoReplyPrefix_returnsTrue() {
        // GIVEN
        let noReplyEmails = [
            "no-reply@example.com",
            "noreply@example.com",
            "postmaster@example.com",
            "catchall@example.com"
        ]

        for email in noReplyEmails {
            let message = createMessage(from: [email])

            // WHEN
            let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

            // THEN
            XCTAssertTrue(result, "Expected \(email) to be detected as no-reply")
        }
    }

    func testNoReplyPrefix_caseInsensitive() {
        // GIVEN
        let noReplyEmails = [
            "NO-REPLY@example.com",
            "NoReply@example.com",
            "POSTMASTER@example.com",
            "CatchAll@example.com"
        ]

        for email in noReplyEmails {
            let message = createMessage(from: [email])

            // WHEN
            let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

            // THEN
            XCTAssertTrue(result, "Expected \(email) to be detected as no-reply (case insensitive)")
        }
    }

    func testNoReplyPrefix_withSubdomain() {
        // GIVEN
        let noReplyEmails = [
            "no-reply@mail.example.com",
            "noreply@notifications.example.com",
            "postmaster@subdomain.example.org"
        ]

        for email in noReplyEmails {
            let message = createMessage(from: [email])

            // WHEN
            let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

            // THEN
            XCTAssertTrue(result, "Expected \(email) to be detected as no-reply")
        }
    }

    func testRegularEmail_returnsFalse() {
        // GIVEN
        let regularEmails = [
            "john.doe@example.com",
            "contact@example.com",
            "support@example.com",
            "info@example.com",
            "hello@example.com"
        ]

        for email in regularEmails {
            let message = createMessage(from: [email])

            // WHEN
            let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

            // THEN
            XCTAssertFalse(result, "Expected \(email) to NOT be detected as no-reply")
        }
    }

    func testNoReplyInDomain_returnsFalse() {
        // GIVEN - no-reply is in domain part, not local part
        let emails = [
            "contact@noreply.example.com",
            "info@no-reply-domain.com"
        ]

        for email in emails {
            let message = createMessage(from: [email])

            // WHEN
            let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

            // THEN
            XCTAssertFalse(result, "Expected \(email) to NOT be detected as no-reply (prefix in domain only)")
        }
    }

    func testNoReplyWithSuffix_returnsTrue() {
        // GIVEN - no-reply prefix with additional characters
        let noReplyEmails = [
            "no-reply-newsletter@example.com",
            "noreply123@example.com",
            "postmaster-auto@example.com",
            "catchall-service@example.com"
        ]

        for email in noReplyEmails {
            let message = createMessage(from: [email])

            // WHEN
            let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

            // THEN
            XCTAssertTrue(result, "Expected \(email) to be detected as no-reply (prefix match)")
        }
    }

    // MARK: - Tests for multiple senders

    func testMultipleFromRecipients_oneNoReply_returnsTrue() {
        // GIVEN
        let message = createMessage(from: ["john@example.com", "noreply@example.com"])

        // WHEN
        let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

        // THEN
        XCTAssertTrue(result, "Expected detection when at least one sender is no-reply")
    }

    func testMultipleFromRecipients_noneNoReply_returnsFalse() {
        // GIVEN
        let message = createMessage(from: ["john@example.com", "jane@example.com"])

        // WHEN
        let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

        // THEN
        XCTAssertFalse(result, "Expected no detection when no sender is no-reply")
    }

    // MARK: - Tests for action types (reply vs replyAll)

    func testReplyAction_checksOnlyFrom() {
        // GIVEN - no-reply in CC, regular in FROM
        let message = createMessage(from: ["john@example.com"], cc: ["noreply@example.com"])

        // WHEN
        let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

        // THEN
        XCTAssertFalse(result, "Reply action should only check FROM recipients")
    }

    func testReplyAllAction_checksFromAndCc() {
        // GIVEN - no-reply in CC, regular in FROM
        let message = createMessage(from: ["john@example.com"], cc: ["noreply@example.com"])

        // WHEN
        let result = NoReplyAlert.verifySenders(message: message, action: .replyAll, currentMailboxEmail: currentMailBoxEmail)

        // THEN
        XCTAssertTrue(result, "ReplyAll action should check FROM and CC recipients")
    }

    func testReplyAllAction_noReplyInFrom_returnsTrue() {
        // GIVEN - no-reply in FROM
        let message = createMessage(from: ["noreply@example.com"], cc: ["jane@example.com"])

        // WHEN
        let result = NoReplyAlert.verifySenders(message: message, action: .replyAll, currentMailboxEmail: currentMailBoxEmail)

        // THEN
        XCTAssertTrue(result, "ReplyAll should detect no-reply in FROM")
    }

    func testReplyAllAction_noNoReply_returnsFalse() {
        // GIVEN - no no-reply addresses
        let message = createMessage(from: ["john@example.com"], cc: ["jane@example.com"])

        // WHEN
        let result = NoReplyAlert.verifySenders(message: message, action: .replyAll, currentMailboxEmail: currentMailBoxEmail)

        // THEN
        XCTAssertFalse(result, "ReplyAll should return false when no no-reply addresses")
    }

    // MARK: - Edge cases

    func testEmptyFromList() {
        // GIVEN
        let message = createMessage(from: [])

        // WHEN
        let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

        // THEN
        XCTAssertFalse(result, "Empty from list should return false")
    }

    func testEmptyEmail() {
        // GIVEN
        let message = createMessage(from: [""])

        // WHEN
        let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

        // THEN
        XCTAssertFalse(result, "Empty email should return false")
    }

    func testEmailWithoutAtSymbol() {
        // GIVEN - malformed email without @
        let message = createMessage(from: ["noreply"])

        // WHEN
        let result = NoReplyAlert.verifySenders(message: message, action: .reply, currentMailboxEmail: currentMailBoxEmail)

        // THEN
        XCTAssertTrue(result, "Email without @ should still check prefix on whole string")
    }

    // MARK: - Tests for noReplyPrefixes constant

    func testNoReplyPrefixesContainsExpectedValues() {
        // GIVEN / WHEN
        let prefixes = NoReplyAlert.noReplyPrefixes

        // THEN
        XCTAssertTrue(prefixes.contains("no-reply"), "Should contain 'no-reply'")
        XCTAssertTrue(prefixes.contains("noreply"), "Should contain 'noreply'")
        XCTAssertTrue(prefixes.contains("postmaster"), "Should contain 'postmaster'")
        XCTAssertTrue(prefixes.contains("catchall"), "Should contain 'catchall'")
        XCTAssertEqual(prefixes.count, 4, "Should have exactly 4 prefixes")
    }
}
