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

public enum SettingsSelectionPage: CaseIterable {
    case theme
    case messageDisplay
    case externalContent
    case cancelDelay
    case mailTransfer
    case swipe

    public var title: String {
        switch self {
        case .theme:
            return MailResourcesStrings.settingsThemeChoiceTitle
        case .messageDisplay:
            return MailResourcesStrings.settingsMessageDisplayTitle
        case .externalContent:
            return MailResourcesStrings.settingsExternalContentTitle
        case .cancelDelay:
            return MailResourcesStrings.settingsCancellationPeriodTitle
        case .mailTransfer:
            return MailResourcesStrings.settingsTransferEmailsTitle
        case .swipe:
            return MailResourcesStrings.settingsSwipeActionsTitle
        }
    }

    public var description: String {
        switch self {
        case .theme:
            return MailResourcesStrings.settingsTheme
        case .messageDisplay:
            return MailResourcesStrings.settingsSelectDisplayModeDescription
        case .externalContent:
            return MailResourcesStrings.settingsSelectDisplayModeDescription
        case .cancelDelay:
            return ""
        case .mailTransfer:
            return ""
        case .swipe:
            return ""
        }
    }
}

class SettingsSelectionViewModel: ObservableObject {
    public var page: SettingsSelectionPage

    init(page: SettingsSelectionPage) {
        self.page = page
    }

    public var tableContent: [ParameterSelectionRow] {
        switch page {
        case .theme:
            return [.themeDark, .themeLight, .themeDefault]
        case .messageDisplay:
            return [.messageDisplaySimple, .messageDisplayThread]
        case .externalContent:
            return [.externalContentAlways, .externalContentAskMe]
        case .cancelDelay:
            return [.cancelDelayDisabled, .cancelDelay10, .cancelDelay20, .cancelDelay30]
        case .mailTransfer:
            return [.mailTransferInBody, .mailTransferAsAttachment]
        case .swipe:
            return [
                .swipeDelete,
                .swipeArchive,
                .swipeRead,
                .swipeMove,
                .swipeReport,
                .swipeSpam,
                .swipeReadAndArchive,
                .swipeQuickAction,
                .swipeNone
            ]
        }
    }
}

public enum ParameterSelectionRow: CaseIterable, Identifiable {
    public var id: Self { self }

    // theme
    case themeLight
    case themeDark
    case themeDefault

    // messageDisplay
    case messageDisplayThread
    case messageDisplaySimple

    // externalContent
    case externalContentAlways
    case externalContentAskMe

    // cancelDelay
    case cancelDelayDisabled
    case cancelDelay10
    case cancelDelay20
    case cancelDelay30

    // mailTransfer
    case mailTransferInBody
    case mailTransferAsAttachment

    // swipe
    case swipeDelete
    case swipeArchive
    case swipeRead
    case swipeMove
    case swipeReport
    case swipeSpam
    case swipeReadAndArchive
    case swipeQuickAction
    case swipeNone

    // TODO: - fix this
    public var image: Image? {
        switch self {
        case .messageDisplayThread:
            return Image(uiImage: MailResourcesAsset.conversationEmail.image)
        case .messageDisplaySimple:
            return Image(uiImage: MailResourcesAsset.singleEmail.image)
        case .themeDark:
            return nil
        case .themeLight:
            return nil
        case .themeDefault:
            return nil
        default:
            return nil
        }
    }

    public var title: String {
        switch self {
        case .messageDisplaySimple:
            return MailResourcesStrings.settingsOptionMessages
        case .messageDisplayThread:
            return MailResourcesStrings.settingsOptionDiscussions
        case .themeLight:
            return MailResourcesStrings.settingsOptionLightTheme
        case .themeDark:
            return MailResourcesStrings.settingsOptionDarkTheme
        case .themeDefault:
            return MailResourcesStrings.settingsDefault
        case .externalContentAlways:
            return MailResourcesStrings.settingsOptionAlways
        case .externalContentAskMe:
            return MailResourcesStrings.settingsOptionAskMe
        case .cancelDelayDisabled:
            return MailResourcesStrings.settingsDisabled
        case .cancelDelay10:
            return MailResourcesStrings.settingsDelaySeconds(10)
        case .cancelDelay20:
            return MailResourcesStrings.settingsDelaySeconds(20)
        case .cancelDelay30:
            return MailResourcesStrings.settingsDelaySeconds(30)
        case .mailTransferInBody:
            return MailResourcesStrings.settingsTransferInBody
        case .mailTransferAsAttachment:
            return MailResourcesStrings.settingsTransferAsAttachment
        case .swipeDelete:
            return MailResourcesStrings.settingsSwipeActionDelete
        case .swipeArchive:
            return MailResourcesStrings.settingsSwipeActionArchive
        case .swipeRead:
            return MailResourcesStrings.settingsSwipeActionReadUnread
        case .swipeMove:
            return MailResourcesStrings.settingsSwipeActionMove
        case .swipeReport:
            // TODO: - Add trad
            return ""
        case .swipeSpam:
            return MailResourcesStrings.settingsSwipeActionSpam
        case .swipeReadAndArchive:
            return MailResourcesStrings.settingsSwipeActionReadAndArchive
        case .swipeQuickAction:
            return MailResourcesStrings.settingsSwipeActionQuickActionsMenu
        case .swipeNone:
            return MailResourcesStrings.settingsSwipeActionNone
        }
    }

    // TODO: - fix that
    public var isSelected: Bool {
        return true
    }
}
