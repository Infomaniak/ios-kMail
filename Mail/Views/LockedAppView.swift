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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct LockedAppView: View {
    @LazyInjectService var appLockHelper: AppLockHelper

    @EnvironmentObject var navigationState: NavigationState

    var body: some View {
        ZStack {
            VStack(spacing: 27) {
                MailResourcesAsset.lock.swiftUIImage
                    .frame(width: 187, height: 187)

                Text(MailResourcesStrings.Localizable.lockAppTitle)
                    .textStyle(.header2)
            }

            VStack {
                MailResourcesAsset.logoText.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: UIConstants.onboardingLogoHeight)

                Spacer()

                MailButton(label: MailResourcesStrings.Localizable.buttonUnlock, action: unlockApp)
                    .mailButtonFullWidth(true)
            }
            .padding(.top, UIConstants.onboardingLogoPaddingTop)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .defaultAppStorage(.shared)
        .onAppear {
            unlockApp()
        }
        .matomoView(view: ["LockedAppView"])
    }

    private func unlockApp() {
        Task {
            if await (try? appLockHelper.evaluatePolicy(reason: MailResourcesStrings.Localizable.lockAppTitle)) == true {
                appLockHelper.setTime()
                Task {
                    navigationState.transitionToRootViewDestination(.mainView)
                }
            }
        }
    }
}

struct LockedAppView_Previews: PreviewProvider {
    static var previews: some View {
        LockedAppView()
    }
}
