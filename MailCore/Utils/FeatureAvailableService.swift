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

import Foundation
import InfomaniakDI

public enum AppFeature {
    case snooze
    case emojiReaction
}

public protocol FeatureAvailableProvider: Sendable {
    func isAvailable(_ feature: AppFeature) -> Bool
}

final class FeatureAvailableService: FeatureAvailableProvider {
    public func isAvailable(_ feature: AppFeature) -> Bool {
        switch feature {
        case .snooze:
            return isSnoozeAvailable()
        case .emojiReaction:
            return isEmojiReactionAvailable()
        }
    }

    private func isSnoozeAvailable() -> Bool {
        @InjectService var featureFlagManageable: FeatureFlagsManageable
        return featureFlagManageable.isEnabled(.mailSnooze) && UserDefaults.shared.threadMode == .conversation
    }

    private func isEmojiReactionAvailable() -> Bool {
        @InjectService var featureFlagManageable: FeatureFlagsManageable
        return featureFlagManageable.isEnabled(.mailEmojiReaction) && UserDefaults.shared.threadMode == .conversation
    }
}
