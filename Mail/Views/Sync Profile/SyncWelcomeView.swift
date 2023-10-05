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
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @Environment(\.colorScheme) private var colorScheme

    @Binding var navigationPath: [SyncProfileStep]

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                MailResourcesAsset.onboardingBackground4.swiftUIImage
                    .resizable()
                    .frame(height: proxy.size.height * 0.62)
                    .foregroundColor(colorScheme == .light ? accentColor.secondary : MailResourcesAsset.backgroundSecondaryColor)
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: UIPadding.medium) {
                MailResourcesAsset.illuSync.swiftUIImage
                Spacer(minLength: UIPadding.medium)
                Text("!Consulter vos calendriers et contacts Infomaniak sur votre appareil")
                    .textStyle(.header1)
                    .multilineTextAlignment(.center)
                HStack {
                    ChipView(text: "iPhone")
                    ChipView(text: "iPad")
                }
                Spacer(minLength: UIPadding.medium)
            }
            .padding(value: .medium)
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
    NavigationView {
        SyncWelcomeView(navigationPath: .constant([]))
    }
    .navigationViewStyle(.stack)
}
