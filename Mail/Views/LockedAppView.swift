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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct LockedAppView: View {
    @LazyInjectService var appLockHelper: AppLockHelper

    @EnvironmentObject var navigationState: RootViewState

    @State private var isEvaluatingPolicy = false

    var body: some View {
        ZStack {
            VStack(spacing: IKPadding.large) {
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

                Button(MailResourcesStrings.Localizable.buttonUnlock, action: unlockApp)
                    .buttonStyle(.ikBorderedProminent)
                    .controlSize(.large)
                    .ikButtonFullWidth(true)
                    .ikButtonLoading(isEvaluatingPolicy)
            }
            .padding(.top, IKPadding.onBoardingLogoTop)
            .padding(.bottom, value: .extraLarge)
        }
        .padding(.horizontal, value: .large)
        .onAppear {
            unlockApp()
        }
        .matomoView(view: ["LockedAppView"])
    }

    private func unlockApp() {
        guard !isEvaluatingPolicy else { return }

        Task {
            isEvaluatingPolicy = true
            if await (try? appLockHelper.evaluatePolicy(reason: MailResourcesStrings.Localizable.lockAppTitle)) == true {
                appLockHelper.setTime()
                Task {
                    navigationState.transitionToMainViewIfPossible(targetAccount: nil, targetMailbox: nil)
                }
            } else {
                isEvaluatingPolicy = false
            }
        }
    }
}

#Preview {
    LockedAppView()
}
