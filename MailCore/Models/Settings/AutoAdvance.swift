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

public enum AutoAdvance: String, CaseIterable, SettingsOptionEnum {
    case previousThread
    case followingThread
    case listOfThread
    case naturalThread

    public var title: String {
        switch self {
        case .previousThread:
            return MailResourcesStrings.Localizable.settingsAutoAdvancePreviousThreadTitle
        case .followingThread:
            return MailResourcesStrings.Localizable.settingsAutoAdvanceFollowingThreadTitle
        case .listOfThread:
            return MailResourcesStrings.Localizable.settingsAutoAdvanceListOfThreadsTitle
        case .naturalThread:
            return MailResourcesStrings.Localizable.settingsAutoAdvanceNaturalThreadTitle
        }
    }

    public var description: String {
        switch self {
        case .previousThread:
            return MailResourcesStrings.Localizable.settingsAutoAdvancePreviousThreadDescription
        case .followingThread:
            return MailResourcesStrings.Localizable.settingsAutoAdvanceFollowingThreadDescription
        case .listOfThread:
            return MailResourcesStrings.Localizable.settingsAutoAdvanceListOfThreadsDescription
        case .naturalThread:
            return MailResourcesStrings.Localizable.settingsAutoAdvanceNaturalThreadDescription
        }
    }

    public var image: Image? {
        return nil
    }

    public var hint: String? {
        if self == .naturalThread {
            return MailResourcesStrings.Localizable.settingsAutoAdvanceNaturalThreadHint
        } else {
            return nil
        }
    }
}
