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
import MailResources
import SwiftUI

struct NoMailboxView: View {
    @Environment(\.openURL) private var openURL

    @State private var isShowingLoginView = false
    let slide = Slide(
        id: 1,
        backgroundImage: MailResourcesAsset.onboardingBackground3.swiftUIImage,
        title: MailResourcesStrings.Localizable.noMailboxTitle,
        description: MailResourcesStrings.Localizable.noMailboxDescription,
        asset: MailResourcesAsset.noMailbox.swiftUIImage
    )

    var body: some View {
        VStack(spacing: 0) {
            SlideView(slide: slide)
                .overlay(alignment: .top) {
                    MailResourcesAsset.logoText.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(height: UIConstants.onboardingLogoHeight)
                        .padding(.top, UIPadding.onBoardingLogoTop)
                }

            VStack(spacing: UIPadding.medium) {
                MailButton(icon: MailResourcesAsset.plus, label: MailResourcesStrings.Localizable.buttonAddEmailAddress) {
                    openURL(URLConstants.ikMe.url)
                }
                .mailButtonFullWidth(true)

                MailButton(label: MailResourcesStrings.Localizable.buttonLogInDifferentAccount) {
                    isShowingLoginView = true
                }
                .mailButtonStyle(.link)
            }
            .padding(.horizontal, value: .medium)
            .padding(.bottom, UIPadding.onBoardingBottomButtons)
        }
        .matomoView(view: ["NoMailboxView"])
        .fullScreenCover(isPresented: $isShowingLoginView) {
            OnboardingView(page: 4, isScrollEnabled: false)
        }
    }
}

struct NoMailboxView_Previews: PreviewProvider {
    static var previews: some View {
        NoMailboxView()
    }
}
