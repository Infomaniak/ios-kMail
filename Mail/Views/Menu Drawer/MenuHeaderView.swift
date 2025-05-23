/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI
import UIKit

struct MenuHeaderView: View {
    @InjectService private var platformDetector: PlatformDetectable

    @EnvironmentObject private var mainViewState: MainViewState

    private var menuDrawerLogoHeight: CGFloat {
        platformDetector.isMac ? 48 : 32
    }

    var body: some View {
        if platformDetector.isMac {
            ZStack {}
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        logoImage(Image(uiImage: MailResourcesAsset.logoText.image))
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        settingsButton
                    }
                }
        } else {
            HStack {
                logoImage(MailResourcesAsset.logoText.swiftUIImage)

                Spacer()

                settingsButton
            }
            .padding(.vertical, value: .medium)
            .padding(.leading, value: .large)
            .padding(.trailing, value: .micro)
            .background(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)
            .clipped()
            .shadow(color: MailResourcesAsset.menuDrawerShadowColor.swiftUIColor, radius: 1, x: 0, y: 2)
        }
    }

    private func logoImage(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(height: menuDrawerLogoHeight)
    }

    private var settingsButton: some View {
        Button {
            mainViewState.settingsViewConfig = SettingsViewConfig(baseNavigationPath: [])
        } label: {
            MailResourcesAsset.cog
                .iconSize(.large)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(MailResourcesStrings.Localizable.settingsTitle)
        .frame(width: menuDrawerLogoHeight, height: menuDrawerLogoHeight)
        .contentShape(Rectangle())
    }
}

#Preview {
    MenuHeaderView()
}
