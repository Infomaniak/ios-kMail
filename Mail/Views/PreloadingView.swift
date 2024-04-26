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

import InfomaniakCore
import InfomaniakDI
import MailCore
import MailCoreUI
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
    @LazyInjectService private var accountManager: AccountManager

    @EnvironmentObject private var rootViewState: RootViewState

    let currentAccount: Account

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .splashScreenIconAlignment)) {
            MailResourcesAsset.backgroundBlueNavBarColor.swiftUIColor
                .ignoresSafeArea()

            VStack(spacing: UIPadding.medium) {
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
                .padding(.bottom, value: .regular)
        }
        .task(id: currentAccount.id) {
            do {
                try await accountManager.updateUser(for: currentAccount)

                if let currentMailboxManager = accountManager.currentMailboxManager {
                    try await currentMailboxManager.refreshAllFolders()
                }

                rootViewState.transitionToRootViewDestination(.mainView)
            } catch let error as MailError where error == MailError.noMailbox {
                rootViewState.transitionToRootViewDestination(.noMailboxes)
            } catch {
                rootViewState.transitionToRootViewDestination(.onboarding)
            }
        }
    }
}

#Preview {
    PreloadingView(currentAccount: PreviewHelper.sampleAccount)
        .environmentObject(RootViewState())
}
