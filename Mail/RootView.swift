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

import MailCore
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var rootViewState: RootViewState

    var body: some View {
        ZStack {
            switch rootViewState.state {
            case .appLocked:
                LockedAppView()
            case .mainView(let mainViewState):
                SplitView(mailboxManager: mainViewState.mailboxManager)
                    .environmentObject(mainViewState)
            case .onboarding:
                OnboardingView()
            case .authorization:
                AuthorizationView()
            case .noMailboxes:
                NoMailboxView()
            case .unavailableMailboxes:
                UnavailableMailboxesView()
            case .updateRequired:
                MailUpdateRequiredView()
            case .preloading(let currentAccount):
                PreloadingView(currentAccount: currentAccount)
            }
        }
    }
}
