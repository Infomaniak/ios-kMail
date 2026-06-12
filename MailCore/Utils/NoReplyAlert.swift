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

enum NoReplyAlert {
    static let noReplyPrefixes: Set = ["no-reply", "noreply", "postmaster", "catchall"]

    static func verifySenders(message: Message, action: Action, currentMailboxEmail: String) -> Bool {
        let isReplyingAll = action == .replyAll
        let recipientHolder = message.recipientsForReplyTo(replyAll: isReplyingAll, currentMailboxEmail: currentMailboxEmail)

        let recipientsToCheck = recipientHolder.cc + recipientHolder.to

        return recipientsToCheck.contains { sender in
            isNoReply(email: sender.email)
        }
    }

    private static func isNoReply(email: String) -> Bool {
        let normalizedEmail = email.lowercased()
        let localPart = normalizedEmail.split(separator: "@", maxSplits: 1).first.map(String.init) ?? normalizedEmail
        return noReplyPrefixes.contains { prefix in
            localPart.hasPrefix(prefix)
        }
    }
}
