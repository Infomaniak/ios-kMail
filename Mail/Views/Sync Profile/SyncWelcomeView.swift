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

struct SyncWelcomeView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Binding var navigationPath: [SyncProfileStep]

    private let slide = Slide(
        id: 0,
        backgroundImage: MailResourcesAsset.onboardingBackground4.swiftUIImage,
        title: MailResourcesStrings.Localizable.syncCalendarsAndContactsTitle,
        description: MailResourcesStrings.Localizable.syncCalendarsAndContactsDescription,
        asset: MailResourcesAsset.syncIllustration.swiftUIImage
    )

    var body: some View {
        SlideView(slide: slide)
            .ignoresSafeArea(edges: .top)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: UIPadding.small) {
                    Button(MailResourcesStrings.Localizable.buttonStart) {
                        matomo.track(eventWithCategory: .syncAutoConfig, name: "start")
                        navigationPath.append(.downloadProfile)
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

#Preview {
    NavigationView {
        SyncWelcomeView(navigationPath: .constant([]))
    }
    .navigationViewStyle(.stack)
}
