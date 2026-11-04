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
import SwiftSoup

/// A thread-safe snapshot of a message body, used to compare it with an absence auto-reply.
public struct ScheduledAbsenceMessageBody: Sendable, Hashable {
    public let content: String
    public let isHTML: Bool

    public init(content: String, isHTML: Bool) {
        self.content = content
        self.isHTML = isHTML
    }

    public init?(body: Body?) {
        guard let body, let content = body.value else { return nil }
        self.init(content: content, isHTML: body.type != .textPlain)
    }
}

public extension ScheduledAbsence {
    /// Mirrors the web `#isMailContentSameAsAbsenceMessage`: the signature is removed from the message, then both texts
    /// are compared ignoring case and whitespace differences.
    @concurrent
    func isAutoReplyDisplayed(in bodies: [ScheduledAbsenceMessageBody]) async -> Bool {
        guard let autoReply = displayableAutoReplyContent else { return false }

        let normalizedAutoReply = Self.normalizedForComparison(autoReply)
        return bodies.contains { body in
            guard let text = Self.plainText(of: body) else { return false }
            return Self.normalizedForComparison(text) == normalizedAutoReply
        }
    }

    internal static func normalizedForComparison(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ").lowercased()
    }

    private static func plainText(of body: ScheduledAbsenceMessageBody) -> String? {
        guard body.isHTML else { return body.content }
        guard let document = try? SwiftSoup.parse(body.content) else { return nil }

        try? document.select(".\(Constants.signatureHTMLClass)").remove()
        return try? document.body()?.text()
    }
}
