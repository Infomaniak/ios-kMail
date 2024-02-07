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

import CocoaLumberjackSwift
import Contacts
import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import MailCore
import MailResources
import Sentry
import SwiftUI
import UIKit

@main
struct MailApp: App {
    /// Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = MailTargetAssembly()

    @LazyInjectService private var refreshAppBackgroundTask: RefreshAppBackgroundTask

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        DDLogInfo("Application starting in foreground ? \(UIApplication.shared.applicationState != .background)")
        refreshAppBackgroundTask.register()
    }

    var body: some Scene {
        UserAccountWindow()

        if #available(iOS 16.0, *) {
            WindowGroup(
                MailResourcesStrings.Localizable.settingsTitle,
                id: DesktopWindowIdentifier.composeWindowIdentifier,
                for: ComposeMessageIntent.self
            ) { $composeMessageIntent in
                if let composeMessageIntent {
                    ComposeMessageIntentView(composeMessageIntent: composeMessageIntent)
                        .standardWindow()
                }
            }
            .defaultAppStorage(.shared)

            WindowGroup(id: DesktopWindowIdentifier.threadWindowIdentifier,
                        for: OpenThreadIntent.self) { $openThreadIntent in
                if let openThreadIntent {
                    OpenThreadIntentView(openThreadIntent: openThreadIntent)
                        .standardWindow()
                }
            }
            .defaultAppStorage(.shared)
        }
    }
}
