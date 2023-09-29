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

struct SyncWelcomeView: View {
    @Binding var navigationPath: [SyncProfileStep]

    var body: some View {
        VStack {
            SlideView(slide: Slide(
                id: 1,
                backgroundImage: MailResourcesAsset.onboardingBackground1.swiftUIImage,
                title: "!Consultez vos calendriers et contacts Infomaniak sur votre téléphone",
                description: "!Consultez vos calendriers et carnets d’adresses sur vos applications Calendrier et Contacts de votre iPhone/iPad.",
                asset: MailResourcesAsset.illuSync.swiftUIImage
            ))
            .ignoresSafeArea(edges: .top)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: UIPadding.medium) {
                MailButton(label: "!Commencer") {
                    navigationPath.append(.downloadProfile)
                }
                .mailButtonFullWidth(true)
            }
            .padding(.horizontal, value: .medium)
            .padding(.bottom, UIPadding.onBoardingBottomButtons)
        }
    }
}

#Preview {
    SyncWelcomeView(navigationPath: .constant([]))
}
