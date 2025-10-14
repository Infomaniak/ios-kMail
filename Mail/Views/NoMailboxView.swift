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

import DesignSystem
import InfomaniakCoreSwiftUI
import InfomaniakOnboarding
import MailCore
import MailResources
import SwiftUI

struct NoMailboxView: View {
    @State private var isShowingLoginView = false

    private let slide = Slide(backgroundImage: MailResourcesAsset.onboardingBackground3.image,
                              backgroundImageTintColor: UserDefaults.shared.accentColor.secondary.color,
                              content: .illustration(MailResourcesAsset.noMailbox.image),
                              bottomView: OnboardingTextView(
                                  title: MailResourcesStrings.Localizable.noMailboxTitle,
                                  description: MailResourcesStrings.Localizable.noMailboxDescription
                              ))

    var body: some View {
        WaveView(slides: [slide], selectedSlide: .constant(0)) { _ in
            Button(MailResourcesStrings.Localizable.buttonLogInDifferentAccount) {
                isShowingLoginView = true
            }
            .buttonStyle(.ikBorderless)
            .controlSize(.large)
            .ikButtonFullWidth(true)
            .padding(.horizontal, value: .large)
            .padding(.bottom, IKPadding.onBoardingBottomButtons)
        }
        .ignoresSafeArea()
        .matomoView(view: ["NoMailboxView"])
        .fullScreenCover(isPresented: $isShowingLoginView) {
            SingleOnboardingView()
        }
    }
}

#Preview {
    NoMailboxView()
}
