/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

public enum ActionType: String, Codable {
    case ignorePreviousRules = "ignore-previous-rules"
    case block
}

public struct ContentRuleAction: Codable {
    public let type: ActionType

    public init(type: ActionType) {
        self.type = type
    }
}

public struct ContentRuleTrigger: Codable {
    public let urlFilter: String

    public init(urlFilter: String) {
        self.urlFilter = urlFilter
    }

    enum CodingKeys: String, CodingKey {
        case urlFilter = "url-filter"
    }
}

public struct ContentRule: Codable {
    public let action: ContentRuleAction
    public let trigger: ContentRuleTrigger

    public init(action: ContentRuleAction, trigger: ContentRuleTrigger) {
        self.action = action
        self.trigger = trigger
    }
}

public enum ContentRuleGenerator {
    static let jsonEncoder = JSONEncoder()

    public static func generateContentRulesJSON(rules: [ContentRule]) -> String? {
        guard let encodedData = try? jsonEncoder.encode(rules) else { return nil }
        return String(decoding: encodedData, as: UTF8.self)
    }
}
