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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

extension VerticalAlignment {
    enum SplashScreenIconAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[VerticalAlignment.center]
        }
    }

    static let splashScreenIconAlignment = VerticalAlignment(SplashScreenIconAlignment.self)
}

struct PreloadingView: View {
    @LazyInjectService private var appLockHelper: AppLockHelper
    @LazyInjectService private var tokenStore: TokenStore
    @LazyInjectService private var appLaunchCounter: AppLaunchCounter
    @LazyInjectService private var accountManager: AccountManager

    @EnvironmentObject private var rootViewState: RootViewState

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .splashScreenIconAlignment)) {
            MailResourcesAsset.backgroundBlueNavBarColor.swiftUIColor
                .ignoresSafeArea()

            VStack(spacing: IKPadding.large) {
                MailResourcesAsset.splashscreenMail.swiftUIImage
                    .frame(maxWidth: 204)
                    .padding(.top, -28)
                    .alignmentGuide(.splashScreenIconAlignment) { d in d[VerticalAlignment.center] }

                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .safeAreaInset(edge: .bottom) {
            MailResourcesAsset.splashscreenInfomaniak.swiftUIImage
                .frame(width: 178)
                .padding(.bottom, value: .medium)
        }
        .task {
            await preloadAndTransitionToRootView()
        }
    }

    func preloadAndTransitionToRootView() async {
        guard !appLaunchCounter.isFirstLaunch else {
            tokenStore.removeAllTokens()
            appLaunchCounter.increase()
            rootViewState.transitionToRootViewState(.onboarding)
            return
        }

        await TokenMigrator().migrateTokensIfNeeded()

        guard let currentAccount = accountManager.getCurrentAccount() else {
            rootViewState.transitionToRootViewState(.onboarding)
            return
        }

        let isAppLocked = UserDefaults.shared.isAppLockEnabled && appLockHelper.isAppLocked
        guard !isAppLocked else {
            rootViewState.transitionToRootViewState(.appLocked)
            return
        }

        do {
            if let targetMailboxManager = accountManager.currentMailboxManager {
                if await accountManager.getCurrentUser() == nil {
                    try await accountManager.updateUser(for: currentAccount)
                }

                if targetMailboxManager.getFolder(with: .inbox) == nil {
                    try await targetMailboxManager.refreshAllFolders()
                }
                await rootViewState.transitionToMainViewIfPossible(
                    targetAccount: currentAccount,
                    targetMailbox: targetMailboxManager.mailbox
                )
                return
            }

            try await accountManager.updateUser(for: currentAccount)

            if let currentMailboxManager = accountManager.currentMailboxManager {
                try await currentMailboxManager.refreshAllFolders()
            }

            await rootViewState.transitionToMainViewIfPossible(targetAccount: currentAccount, targetMailbox: nil)
        } catch let error as MailError where error == MailError.noMailbox {
            rootViewState.transitionToRootViewState(.noMailboxes)
        } catch {
            rootViewState.transitionToRootViewState(.onboarding)
        }
    }
}

#Preview {
    PreloadingView()
        .environmentObject(RootViewState())
}
