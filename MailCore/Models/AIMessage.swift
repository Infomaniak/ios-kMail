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

public enum AIOutputFormat: String, Codable {
    case `default`, mail
}

public struct AIRequest: Codable {
    public let messages: [AIMessage]
    public let output: AIOutputFormat
}

public struct AIResponse: Codable {
    public let contextId: String?
    public let tokensUsed: Int
    public let content: String
}

public enum AIMessageType: String, Codable {
    case user, context
}

public struct AIMessage: Codable {
    public let type: AIMessageType
    public let content: String

    public init(type: AIMessageType, content: String) {
        self.type = type
        self.content = content
    }
}
