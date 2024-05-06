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
import UIKit

public enum DefaultPreferences {
    public static let notificationsEnabled = true
    public static let appLock = false
    public static let threadDensity = ThreadDensity.large
    public static let externalContent = ExternalContent.always
    public static let theme = Theme.system
    public static let accentColor = AccentColor.pink
    public static let swipeLeading = Action.noAction
    public static let swipeFullLeading = Action.markAsRead
    public static let swipeTrailing = Action.quickActionPanel
    public static let swipeFullTrailing = Action.delete
    public static let cancelDelay = CancelDelay.seconds10
    public static let forwardMode = ForwardMode.inline
    public static let acknowledgement = false
    public static let includeOriginalInReply = false
    public static let threadMode = ThreadMode.conversation
    public static let featureFlags: FeatureFlagsManageable.AppFeatureFlags = [:]
    public static let shouldPresentAIFeature = true
    public static let aiEngine = AIEngine.falcon
    public static let autoAdvance = UIDevice.current.userInterfaceIdiom == .pad ? AutoAdvance.followingThread : AutoAdvance
        .listOfThread
    public static let updateVersionViewDismissed = false
    public static let matomoAuthorized = true
    public static let sentryAuthorized = true
}
