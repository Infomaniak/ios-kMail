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

struct AuthorizationView: View {
    let contactSlide = Slide(
        id: 1,
        backgroundImage: MailResourcesAsset.onboardingBackground3.swiftUIImage,
        title: MailResourcesStrings.Localizable.noMailboxTitle,
        description: MailResourcesStrings.Localizable.noMailboxDescription,
        asset: MailResourcesAsset.authorizationContact.swiftUIImage
    )
    let notificationSlide = Slide(
        id: 1,
        backgroundImage: MailResourcesAsset.onboardingBackground3.swiftUIImage,
        title: MailResourcesStrings.Localizable.noMailboxTitle,
        description: MailResourcesStrings.Localizable.noMailboxDescription,
        asset: MailResourcesAsset.authorizationNotification.swiftUIImage
    )

    var body: some View {
        SlideView(slide: contactSlide)
            .overlay(alignment: .top) {
                MailResourcesAsset.logoText.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: UIConstants.onboardingLogoHeight)
                    .padding(.top, UIPadding.onBoardingLogoTop)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: UIPadding.small) {
                    Button(MailResourcesStrings.Localizable.contentDescriptionButtonNext) {
                        // TODO:
                    }
                    .buttonStyle(.ikPlain)
                    .controlSize(.large)
                    .ikButtonFullWidth(true)
                }
                .padding(.horizontal, value: .medium)
                .padding(.bottom, UIPadding.onBoardingBottomButtons)
            }
    }
}

struct AuthorizationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthorizationView()
    }
}
