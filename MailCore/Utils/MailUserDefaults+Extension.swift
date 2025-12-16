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
import InfomaniakCore
import SwiftUI

public protocol SettingsOptionEnum {
    var title: String { get }
    var image: Image? { get }
    var hint: String? { get }
}

public extension UserDefaults.Keys {
    static let currentMailboxId = UserDefaults.Keys(rawValue: "currentMailboxId")
    static let currentMailUserId = UserDefaults.Keys(rawValue: "currentMailUserId")
    static let notificationsEnabled = UserDefaults.Keys(rawValue: "notificationsEnabled")
    static let appLock = UserDefaults.Keys(rawValue: "appLock")
    static let threadDensity = UserDefaults.Keys(rawValue: "threadDensity")
    static let externalContent = UserDefaults.Keys(rawValue: "externalContent")
    static let theme = UserDefaults.Keys(rawValue: "theme")
    static let accentColor = UserDefaults.Keys(rawValue: "accentColor")
    static let swipeLeading = UserDefaults.Keys(rawValue: "swipeShortRight")
    static let swipeFullLeading = UserDefaults.Keys(rawValue: "swipeLongRight")
    static let swipeTrailing = UserDefaults.Keys(rawValue: "swipeShortLeft")
    static let swipeFullTrailing = UserDefaults.Keys(rawValue: "swipeLongLeft")
    static let cancelDelay = UserDefaults.Keys(rawValue: "cancelDelay")
    static let forwardMode = UserDefaults.Keys(rawValue: "forwardMode")
    static let acknowledgement = UserDefaults.Keys(rawValue: "acknowledgement")
    static let includeOriginalInReply = UserDefaults.Keys(rawValue: "includeOriginalInReply")
    static let threadMode = UserDefaults.Keys(rawValue: "threadMode")
    static let featureFlags = UserDefaults.Keys(rawValue: "featureFlags")
    static let shouldPresentAIFeature = UserDefaults.Keys(rawValue: "shouldPresentAIFeature")
    static let shouldPresentSyncDiscovery = UserDefaults.Keys(rawValue: "shouldPresentSyncDiscovery")
    static let shouldPresentSetAsDefaultDiscovery = UserDefaults.Keys(rawValue: "shouldPresentSetAsDefaultDiscovery")
    static let shouldPresentEncryptAd = UserDefaults.Keys(rawValue: "shouldPresentEncryptAd")
    static let autoAdvance = UserDefaults.Keys(rawValue: "autoAdvance")
    static let hasDismissedUpdateVersionView = UserDefaults.Keys(rawValue: "hasDismissedUpdateVersionView")
    static let matomoAuthorized = UserDefaults.Keys(rawValue: "matomoAuthorized")
    static let sentryAuthorized = UserDefaults.Keys(rawValue: "sentryAuthorized")
    static let nextShowQuotasAlert = UserDefaults.Keys(rawValue: "nextShowQuotasAlert")
    static let nextShowSync = UserDefaults.Keys(rawValue: "nextShowSync")
    static let showSyncCounter = UserDefaults.Keys(rawValue: "showSyncCounter")
    static let hasDismissedMacDisclaimerView = UserDefaults.Keys(rawValue: "hasDismissedMacDisclaimerView")
    static let lastCustomScheduledDraftDate = UserDefaults.Keys(rawValue: "lastCustomScheduledDraftDate")
    static let lastCustomSnoozeDate = UserDefaults.Keys(rawValue: "lastCustomSnoozeDate")
}

public extension UserDefaults {
    static let shared = UserDefaults(suiteName: AccountManager.appGroup)!

    var currentMailboxId: Int {
        get {
            return integer(forKey: key(.currentMailboxId))
        }
        set {
            set(newValue, forKey: key(.currentMailboxId))
        }
    }

    var currentMailUserId: Int {
        get {
            return integer(forKey: key(.currentMailUserId))
        }
        set {
            set(newValue, forKey: key(.currentMailUserId))
        }
    }

    var isNotificationEnabled: Bool {
        get {
            if object(forKey: key(.notificationsEnabled)) == nil {
                set(DefaultPreferences.notificationsEnabled, forKey: key(.notificationsEnabled))
            }
            return bool(forKey: key(.notificationsEnabled))
        }
        set {
            set(newValue, forKey: key(.notificationsEnabled))
        }
    }

    var isAppLockEnabled: Bool {
        get {
            if object(forKey: key(.appLock)) == nil {
                set(DefaultPreferences.appLock, forKey: key(.appLock))
            }
            return bool(forKey: key(.appLock))
        }
        set {
            set(newValue, forKey: key(.appLock))
        }
    }

    var threadDensity: ThreadDensity {
        get {
            return ThreadDensity(rawValue: string(forKey: key(.threadDensity)) ?? "") ?? DefaultPreferences.threadDensity
        }
        set {
            set(newValue.rawValue, forKey: key(.threadDensity))
        }
    }

    var displayExternalContent: ExternalContent {
        get {
            return ExternalContent(rawValue: string(forKey: key(.externalContent)) ?? "") ?? DefaultPreferences.externalContent
        }
        set {
            set(newValue.rawValue, forKey: key(.externalContent))
        }
    }

    var theme: Theme {
        get {
            return Theme(rawValue: string(forKey: key(.theme)) ?? "") ?? DefaultPreferences.theme
        }
        set {
            setValue(newValue.rawValue, forKey: key(.theme))
        }
    }

    var accentColor: AccentColor {
        get {
            return AccentColor(rawValue: string(forKey: key(.accentColor)) ?? "") ?? DefaultPreferences.accentColor
        }
        set {
            setValue(newValue.rawValue, forKey: key(.accentColor))
        }
    }

    var swipeLeading: Action {
        get {
            return Action(rawValue: string(forKey: key(.swipeLeading)) ?? "") ?? DefaultPreferences.swipeLeading
        }
        set {
            set(newValue.rawValue, forKey: key(.swipeLeading))
        }
    }

    var swipeFullLeading: Action {
        get {
            return Action(rawValue: string(forKey: key(.swipeFullLeading)) ?? "") ?? DefaultPreferences.swipeFullLeading
        }
        set {
            set(newValue.rawValue, forKey: key(.swipeFullLeading))
        }
    }

    var swipeTrailing: Action {
        get {
            return Action(rawValue: string(forKey: key(.swipeTrailing)) ?? "") ?? DefaultPreferences.swipeTrailing
        }
        set {
            set(newValue.rawValue, forKey: key(.swipeTrailing))
        }
    }

    var swipeFullTrailing: Action {
        get {
            return Action(rawValue: string(forKey: key(.swipeFullTrailing)) ?? "") ?? DefaultPreferences.swipeFullTrailing
        }
        set {
            set(newValue.rawValue, forKey: key(.swipeFullTrailing))
        }
    }

    var cancelSendDelay: CancelDelay {
        get {
            if object(forKey: key(.cancelDelay)) == nil {
                set(DefaultPreferences.cancelDelay.rawValue, forKey: key(.cancelDelay))
            }
            return CancelDelay(rawValue: integer(forKey: key(.cancelDelay))) ?? DefaultPreferences.cancelDelay
        }
        set {
            set(newValue.rawValue, forKey: key(.cancelDelay))
        }
    }

    var forwardMode: ForwardMode {
        get {
            ForwardMode(rawValue: string(forKey: key(.forwardMode)) ?? "") ?? DefaultPreferences.forwardMode
        }
        set {
            set(newValue.rawValue, forKey: key(.forwardMode))
        }
    }

    var includeOriginalInReply: Bool {
        get {
            if object(forKey: key(.includeOriginalInReply)) == nil {
                set(DefaultPreferences.includeOriginalInReply, forKey: key(.includeOriginalInReply))
            }
            return bool(forKey: key(.includeOriginalInReply))
        }
        set {
            set(newValue, forKey: key(.includeOriginalInReply))
        }
    }

    var isMatomoAuthorized: Bool {
        get {
            if object(forKey: key(.matomoAuthorized)) == nil {
                set(DefaultPreferences.matomoAuthorized, forKey: key(.matomoAuthorized))
            }
            return bool(forKey: key(.matomoAuthorized))
        }
        set {
            set(newValue, forKey: key(.matomoAuthorized))
        }
    }

    var isSentryAuthorized: Bool {
        get {
            if object(forKey: key(.sentryAuthorized)) == nil {
                set(DefaultPreferences.sentryAuthorized, forKey: key(.sentryAuthorized))
            }
            return bool(forKey: key(.sentryAuthorized))
        }
        set {
            set(newValue, forKey: key(.sentryAuthorized))
        }
    }

    var acknowledgement: Bool {
        get {
            if object(forKey: key(.acknowledgement)) == nil {
                set(DefaultPreferences.acknowledgement, forKey: key(.acknowledgement))
            }
            return bool(forKey: key(.acknowledgement))
        }
        set {
            set(newValue, forKey: key(.acknowledgement))
        }
    }

    var threadMode: ThreadMode {
        get {
            return ThreadMode(rawValue: string(forKey: key(.threadMode)) ?? "") ?? DefaultPreferences.threadMode
        }
        set {
            set(newValue.rawValue, forKey: key(.threadMode))
        }
    }

    var featureFlags: FeatureFlagsManageable.AppFeatureFlags {
        get {
            guard let storedValue = object(forKey: key(.featureFlags)) as? Data,
                  let decodedValue = try? JSONDecoder().decode(FeatureFlagsManageable.AppFeatureFlags.self, from: storedValue)
            else {
                return DefaultPreferences.featureFlags
            }
            return decodedValue
        }
        set {
            guard let encodedValue = try? JSONEncoder().encode(newValue) else { return }
            set(encodedValue, forKey: key(.featureFlags))
        }
    }

    var shouldPresentAIFeature: Bool {
        get {
            if object(forKey: key(.shouldPresentAIFeature)) == nil {
                set(DefaultPreferences.shouldPresentAIFeature, forKey: key(.shouldPresentAIFeature))
            }
            return bool(forKey: key(.shouldPresentAIFeature))
        }
        set {
            set(newValue, forKey: key(.shouldPresentAIFeature))
        }
    }

    var shouldPresentSyncDiscovery: Bool {
        get {
            if object(forKey: key(.shouldPresentSyncDiscovery)) == nil {
                set(true, forKey: key(.shouldPresentSyncDiscovery))
            }
            return bool(forKey: key(.shouldPresentSyncDiscovery))
        }
        set {
            set(newValue, forKey: key(.shouldPresentSyncDiscovery))
        }
    }

    var shouldPresentSetAsDefaultDiscovery: Bool {
        get {
            if object(forKey: key(.shouldPresentSetAsDefaultDiscovery)) == nil {
                set(true, forKey: key(.shouldPresentSetAsDefaultDiscovery))
            }
            return bool(forKey: key(.shouldPresentSetAsDefaultDiscovery))
        }
        set {
            set(newValue, forKey: key(.shouldPresentSetAsDefaultDiscovery))
        }
    }

    var shouldPresentEncryptAd: Bool {
        get {
            if object(forKey: key(.shouldPresentEncryptAd)) == nil {
                set(true, forKey: key(.shouldPresentEncryptAd))
            }
            return bool(forKey: key(.shouldPresentEncryptAd))
        }
        set {
            set(newValue, forKey: key(.shouldPresentEncryptAd))
        }
    }

    var autoAdvance: AutoAdvance {
        get {
            return AutoAdvance(rawValue: string(forKey: key(.autoAdvance)) ?? "") ?? DefaultPreferences.autoAdvance
        }
        set {
            set(newValue.rawValue, forKey: key(.autoAdvance))
        }
    }

    var nextShowQuotasAlert: Int {
        get {
            return integer(forKey: key(.nextShowQuotasAlert))
        }
        set {
            set(newValue, forKey: key(.nextShowQuotasAlert))
        }
    }

    var nextShowSync: Int {
        get {
            if object(forKey: key(.nextShowSync)) == nil {
                set(Constants.minimumOpeningBeforeSync, forKey: key(.nextShowSync))
            }
            return integer(forKey: key(.nextShowSync))
        }
        set {
            set(newValue, forKey: key(.nextShowSync))
        }
    }

    var showSyncCounter: Int {
        get {
            return integer(forKey: key(.showSyncCounter))
        }
        set {
            set(newValue, forKey: key(.showSyncCounter))
        }
    }

    var lastCustomScheduledDraftDate: Date {
        get {
            let timeIntervalSince1970 = double(forKey: key(.lastCustomScheduledDraftDate))
            return Date(timeIntervalSince1970: timeIntervalSince1970)
        }
        set {
            set(newValue.timeIntervalSince1970, forKey: key(.lastCustomScheduledDraftDate))
        }
    }

    var lastCustomSnoozeDate: Date {
        get {
            let timeIntervalSince1970 = double(forKey: key(.lastCustomSnoozeDate))
            return Date(timeIntervalSince1970: timeIntervalSince1970)
        }
        set {
            set(newValue.timeIntervalSince1970, forKey: key(.lastCustomSnoozeDate))
        }
    }
}
