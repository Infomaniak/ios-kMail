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

import Combine
import Foundation
import InfomaniakCore
import InfomaniakDI
import Sentry
import SwiftUI

public enum FeatureFlag: String, Codable {
    case aiMailComposer = "ai-mail-composer"
    case bimi
    case scheduleSendDraft = "schedule-send-draft"
    case mailSnooze = "mail-snooze"
    case mailEmojiReaction = "mail-emoji-reaction"
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self)

        if let featureFlag = FeatureFlag(rawValue: rawString) {
            self = featureFlag
        } else {
            self = .unknown
        }
    }
}

public final class FeatureFlagsManager: FeatureFlagsManageable {
    @LazyInjectService private var accountManager: AccountManager

    private var enabledFeatures: SendableDictionary<AppFeatureFlags.Key, AppFeatureFlags.Value>

    public init() {
        enabledFeatures = SendableDictionary(content: UserDefaults.shared.featureFlags)
    }

    public func isEnabled(_ feature: FeatureFlag) -> Bool {
        guard isEnabledLocally(feature) else { return false }

        guard let mailboxUUID = accountManager.currentMailboxManager?.mailbox.uuid,
              let userFeatures = enabledFeatures.value(for: mailboxUUID) else { return false }

        return userFeatures.contains(feature)
    }

    // periphery:ignore - Reserved for future use
    private func isEnabledLocally(_ feature: FeatureFlag) -> Bool {
        true
    }

    public func feature(_ feature: FeatureFlag, on: () -> Void, off: (() -> Void)?) {
        if isEnabled(feature) {
            on()
        } else {
            off?()
        }
    }

    public func fetchFlags() async throws {
        guard let currentMailboxManager = accountManager.currentMailboxManager else { return }

        let mailboxUUID = currentMailboxManager.mailbox.uuid
        if enabledFeatures.value(for: mailboxUUID) == nil {
            enabledFeatures.setValue(Constants.defaultFeatureFlags, for: mailboxUUID)
        }

        let enabledFlags = try await currentMailboxManager.apiFetcher.featureFlag(mailboxUUID)

        enabledFeatures.setValue(enabledFlags, for: mailboxUUID)
        UserDefaults.shared.featureFlags[mailboxUUID] = enabledFlags
    }
}
