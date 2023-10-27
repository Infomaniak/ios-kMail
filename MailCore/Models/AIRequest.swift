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

public enum AIOutputFormat: String, Codable {
    case `default`, mail
}

public enum AIEngine: String, CaseIterable, SettingsOptionEnum, Codable {
    case falcon
    case chatGPT = "gpt"

    public var title: String {
        switch self {
        case .falcon:
            return MailResourcesStrings.Localizable.aiEngineFalcon
        case .chatGPT:
            return MailResourcesStrings.Localizable.aiEngineChatGpt
        }
    }

    public var image: Image? {
        switch self {
        case .falcon:
            return MailResourcesAsset.aiLogo.swiftUIImage
        case .chatGPT:
            return MailResourcesAsset.chatGPT.swiftUIImage
        }
    }

    public var matomoName: String {
        switch self {
        case .falcon:
            return "falcon"
        case .chatGPT:
            return "chatGpt"
        }
    }
}

public protocol AIRequest: Codable {
    var engine: AIEngine { get }
}

public struct AIConversationRequest: AIRequest {
    public let messages: [AIMessage]
    public let output: AIOutputFormat
    public let engine: AIEngine
}

public struct AIShortcutRequest: AIRequest {
    public let engine: AIEngine
}
