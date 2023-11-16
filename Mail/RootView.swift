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

import MailCore
import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @EnvironmentObject private var navigationState: NavigationState

    var body: some View {
        ZStack {
            switch navigationState.rootViewState {
            case .appLocked:
                LockedAppView()
            case .mainView(let currentMailboxManager, let initialFolder):
                SplitView(mailboxManager: currentMailboxManager)
                    .environmentObject(MainViewState(mailboxManager: currentMailboxManager, selectedFolder: initialFolder))
            case .onboarding:
                OnboardingView()
            case .noMailboxes:
                NoMailboxView()
            case .unavailableMailboxes:
                UnavailableMailboxesView()
            }
        }
        .environment(\.isCompactWindow, horizontalSizeClass == .compact || verticalSizeClass == .compact)
    }
}
