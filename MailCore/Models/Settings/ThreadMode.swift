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

public enum ThreadMode: String, CaseIterable, SettingsOptionEnum {
    case discussion
    case message

    public var title: String {
        switch self {
        case .discussion:
            return MailResourcesStrings.Localizable.settingsOptionDiscussions
        case .message:
            return MailResourcesStrings.Localizable.settingsOptionMessages
        }
    }

    public var value: Bool {
        return self == .discussion
    }

    public var image: Image? {
        switch self {
        case .discussion:
            return Image(MailResourcesAsset.conversationEmail.name)
        case .message:
            return Image(MailResourcesAsset.singleEmail.name)
        }
    }
}
