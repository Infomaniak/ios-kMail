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
import Combine
import Foundation
import InfomaniakDI
import Sentry
import SwiftUI

public enum FeatureFlag: String, Codable {
    case aiMailComposer = "ai-mail-composer"
    case bimi
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self)

        if let featureFlag = FeatureFlag(rawValue: rawString) {
            self = featureFlag
        } else {
            self = .unknown
            SentrySDK.capture(message: "FeatureFlag: Unknown feature") { scope in
                scope.setLevel(.info)
                scope.setExtra(value: rawString, key: "Feature name")
            }
        }
    }
}

public final class FeatureFlagsManager: FeatureFlagsManageable {
    @InjectService private var accountManager: AccountManager

    private var enabledFeatures: AppFeatureFlags

    public init() {
        enabledFeatures = UserDefaults.shared.featureFlags
    }

    public func isEnabled(_ feature: FeatureFlag) -> Bool {
        guard let userFeatures = UserDefaults.shared.featureFlags[accountManager.currentUserId] else { return false }
        return userFeatures.contains(feature)
    }

    public func feature(_ feature: FeatureFlag, on: () -> Void, off: (() -> Void)?) {
        if isEnabled(feature) {
            on()
        } else {
            off?()
        }
    }

    public func fetchFlags() async throws {
        if enabledFeatures[accountManager.currentUserId] == nil {
            enabledFeatures[accountManager.currentUserId] = Constants.defaultFeatureFlags
        }

        guard let apiFetcher = accountManager.currentApiFetcher else { return }
        enabledFeatures[accountManager.currentUserId] = try await apiFetcher.featureFlag()
        UserDefaults.shared.featureFlags = enabledFeatures
    }
}
