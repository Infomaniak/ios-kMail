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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import Social
import SwiftUI
import UIKit

struct ComposeMessageWrapperView: View {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var featureFlagsManager: FeatureFlagsManageable

    let itemProviders: [NSItemProvider]
    let dismissHandler: SimpleClosure

    var body: some View {
        if let mailboxManager = accountManager.currentMailboxManager {
            ComposeMessageIntentView(composeMessageIntent: .new(originMailboxManager: mailboxManager), attachments: itemProviders)
                .environmentObject(mailboxManager)
                .environment(\.dismissModal) {
                    dismissHandler(())
                }
                .task {
                    try? await featureFlagsManager.fetchFlags()
                }
        } else {
            PleaseLoginView(tapHandler: dismissHandler)
        }
    }
}

struct PleaseLoginView: View {
    @State var slide = Slide.onBoardingSlides.first!

    var tapHandler: SimpleClosure

    var body: some View {
        VStack {
            MailShareExtensionAsset.logoText.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(height: UIConstants.onboardingLogoHeight)
                .padding(.top, UIPadding.onBoardingLogoTop)
            Text(MailResourcesStrings.Localizable.pleaseLogInFirst)
                .textStyle(.header2)
                .padding(.top, UIPadding.onBoardingLogoTop)
            LottieView(configuration: slide.lottieConfiguration!)
            Spacer()
        }.onTapGesture {
            tapHandler(())
        }
    }
}
