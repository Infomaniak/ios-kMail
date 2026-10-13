/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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
@testable import MailCore
import Testing

@Suite
struct MailboxDecodingTests {
    @Test("Decodes the external mail gateway flag")
    func decodesExternalMailGatewayFlag() throws {
        let mailbox = try JSONDecoder().decode(Mailbox.self, from: mailboxData(useExternalMailGateway: true))

        #expect(mailbox.useExternalMailGateway)
    }

    @Test("Defaults the external mail gateway flag to false when missing")
    func defaultsExternalMailGatewayFlagToFalseWhenMissing() throws {
        let mailbox = try JSONDecoder().decode(Mailbox.self, from: mailboxData(useExternalMailGateway: nil))

        #expect(!mailbox.useExternalMailGateway)
    }

    private func mailboxData(useExternalMailGateway: Bool?) throws -> Data {
        var mailbox: [String: Any] = [
            "uuid": "mailbox-uuid",
            "email": "test@example.com",
            "emailIdn": "test@example.com",
            "mailbox": "test",
            "accessId": "access-id",
            "mailboxId": 1,
            "hostingId": 1,
            "isPrimary": false,
            "isLocked": false,
            "isSpamFilter": false,
            "dailyLimit": 0,
            "unseenMessages": 0
        ]
        if let useExternalMailGateway {
            mailbox["useExternalMailGateway"] = useExternalMailGateway
        }
        return try JSONSerialization.data(withJSONObject: mailbox)
    }
}
