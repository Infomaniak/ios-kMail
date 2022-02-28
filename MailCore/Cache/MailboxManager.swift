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

public class MailboxManager {
    public class MailboxManagerConstants {
        private let fileManager = FileManager.default
        public let rootDocumentsURL: URL
        public let groupDirectoryURL: URL

        init() {
            groupDirectoryURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AccountManager.appGroup)!
            rootDocumentsURL = groupDirectoryURL.appendingPathComponent("mailboxes", isDirectory: true)
            try? fileManager.setAttributes(
                [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: groupDirectoryURL.path
            )
            try? FileManager.default.createDirectory(
                atPath: rootDocumentsURL.path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    public static let constants = MailboxManagerConstants()

    public var mailbox: Mailbox
    public private(set) var apiFetcher: MailApiFetcher

    init(mailbox: Mailbox, apiFetcher: MailApiFetcher) {
        self.mailbox = mailbox
        self.apiFetcher = apiFetcher
    }

    public func folders() async throws -> [Folder] {
        do {
            let folders = try await apiFetcher.folders(mailbox: mailbox)
            return folders
        } catch {
            throw error
        }
    }
}
