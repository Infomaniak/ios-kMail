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

import MailResources
import SwiftUI

public enum SpamHeaderType: Equatable, Hashable {
    case moveInSpam
    case enableSpamFilter
    case unblockRecipient(String)

    public var message: String {
        switch self {
        case .moveInSpam:
            MailResourcesStrings.Localizable.messageIsSpamShouldMoveToSpam
        case .enableSpamFilter:
            MailResourcesStrings.Localizable.messageIsSpamShouldActivateFilter
        case .unblockRecipient(let recipient):
            MailResourcesStrings.Localizable.messageIsSpamBecauseSenderIsBlocked(recipient)
        }
    }

    public var buttonTitle: String {
        switch self {
        case .moveInSpam:
            MailResourcesStrings.Localizable.moveInSpamButton
        case .enableSpamFilter:
            MailResourcesStrings.Localizable.enableFilterButton
        case .unblockRecipient:
            MailResourcesStrings.Localizable.unblockButton
        }
    }

    public var icon: Image {
        switch self {
        case .unblockRecipient:
            MailResourcesAsset.infoFill.swiftUIImage
        default:
            MailResourcesAsset.warningFill.swiftUIImage
        }
    }

    public static func == (lhs: SpamHeaderType, rhs: SpamHeaderType) -> Bool {
        switch (lhs, rhs) {
        case (.moveInSpam, .moveInSpam):
            return true
        case (.enableSpamFilter, .enableSpamFilter):
            return true
        case (.unblockRecipient(let recipient1), .unblockRecipient(let recipient2)):
            return recipient1 == recipient2
        default:
            return false
        }
    }
}
