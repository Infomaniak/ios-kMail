/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import SwiftUI

/// Something that can managed feature flags
public protocol FeatureFlagsManageable {
    typealias MailboxUUID = String
    typealias AppFeatureFlags = [MailboxUUID: [FeatureFlag]]

    /// Check if a given feature is enabled for the current mailbox
    func isEnabled(_ feature: FeatureFlag) -> Bool

    /// Execute the correct closure depending if a given feature is enabled or not for the current mailbox
    func feature(_ feature: FeatureFlag, on: () -> Void, off: (() -> Void)?)

    /// Refresh the flags for the current mailbox
    func fetchFlags() async throws
}
