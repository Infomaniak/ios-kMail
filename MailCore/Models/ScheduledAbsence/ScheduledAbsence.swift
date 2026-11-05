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

public struct ScheduledAbsence: Decodable, Sendable, Hashable {
    public let uuid: String
    public let statusText: String?
    public let autoReplyContent: String?

    public init(
        uuid: String,
        statusText: String? = nil,
        autoReplyContent: String? = nil
    ) {
        self.uuid = uuid
        self.statusText = statusText
        self.autoReplyContent = autoReplyContent
    }

    public var displayableStatusText: String? {
        return Self.displayable(statusText)
    }

    public var displayableAutoReplyContent: String? {
        return Self.displayable(autoReplyContent)
    }

    private static func displayable(_ text: String?) -> String? {
        guard let text = text?.trimmed, !text.isEmpty else { return nil }
        return text
    }
}
