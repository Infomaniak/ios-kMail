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

import Lottie
import MailCore
import MailResources
import SwiftUI

struct NoMailboxView: View {
    @Environment(\.window) var window

    let slide = Slide(
        id: 1,
        backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground3),
        title: MailResourcesStrings.Localizable.noMailboxTitle,
        description: MailResourcesStrings.Localizable.noMailboxDescription,
        animationFile: "illu_no_mailbox",
        lottieConfiguration: LottieConfiguration(id: 1, loopFrameStart: 42, loopFrameEnd: 112)
    )

    var body: some View {
        VStack(spacing: 0) {
            SlideView(slide: slide, updateAnimationColors: updateAnimationColors)
                .overlay(alignment: .top) {
                    Image(resource: MailResourcesAsset.logoText)
                        .resizable()
                        .scaledToFit()
                        .frame(height: Constants.onboardingLogoHeight)
                        .padding(.top, 28)
                }

            VStack(spacing: 24) {
                LargeButton {
                    UIApplication.shared.open(URLConstants.ikMe.url)
                } label: {
                    Label(MailResourcesStrings.Localizable.buttonAddEmailAddress, systemImage: "plus")
                }

                Button {
                    (window?.windowScene?.delegate as? SceneDelegate)?.showLoginView()
                } label: {
                    Text(MailResourcesStrings.Localizable.buttonLogInDifferentAccount)
                        .textStyle(.bodyMediumAccent)
                }
            }
            .frame(height: Constants.onboardingButtonHeight + Constants.onboardingBottomButtonPadding, alignment: .top)
        }
    }

    private func updateAnimationColors(_ animation: LottieAnimationView, _ configuration: LottieConfiguration) {
        IlluColors.noMailboxAllColors.forEach { $0.applyColors(to: animation) }

        if UserDefaults.shared.accentColor == .pink {
            IlluColors.illuNoMailboxPinkColors.forEach { $0.applyColors(to: animation) }
        } else {
            IlluColors.illuNoMailboxBlueColors.forEach { $0.applyColors(to: animation) }
        }
    }
}

struct NoMailboxView_Previews: PreviewProvider {
    static var previews: some View {
        NoMailboxView()
    }
}
