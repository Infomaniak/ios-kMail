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

import CoreTransferable
import Foundation
import MailCore

struct LazyMailShareLink: Transferable {
    private struct InvalidLinkError: Error {}

    let message: Message
    let mailboxManager: MailboxManager

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { (item: LazyMailShareLink) async throws -> URL in
            let result = try await item.mailboxManager.apiFetcher.shareMailLink(message: item.message)
            guard let url = URL(string: result.url) else { throw InvalidLinkError() }
            return url
        }
    }
}
