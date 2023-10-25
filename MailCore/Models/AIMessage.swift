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
import MailResources
import SwiftUI

public enum AIEngine: String, CaseIterable, SettingsOptionEnum, Codable {
    case falcon
    case chatGPT = "gpt"

    public var title: String {
        switch self {
        case .falcon:
            return "IA Souveraine (Falcon LLM)"
        case .chatGPT:
            return "ChatGPT"
        }
    }

    public var image: Image? {
        switch self {
        case .falcon:
            return MailResourcesAsset.aiLogo.swiftUIImage
        case .chatGPT:
            // TODO: Import correct image
            return MailResourcesAsset.themeLight.swiftUIImage
        }
    }
}

public enum AIMessageType: String, Codable {
    case user, context, assistant
}

public struct AIMessage: Codable {
    public let type: AIMessageType
    public let content: String

    public init(type: AIMessageType, content: String) {
        self.type = type
        self.content = content
    }
}
