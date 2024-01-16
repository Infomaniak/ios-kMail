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
import UIKit

struct MenuHeaderView: View {
    @EnvironmentObject private var mainViewState: MainViewState

    var body: some View {
        HStack {
            MailResourcesAsset.logoText.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(height: UIConstants.menuDrawerLogoHeight)

            Spacer()

            Button {
                mainViewState.settingsViewConfig = SettingsViewConfig(baseNavigationPath: [])
            } label: {
                IKIcon(MailResourcesAsset.cog, size: .large)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(MailResourcesStrings.Localizable.settingsTitle)
            .frame(width: UIConstants.menuDrawerLogoHeight, height: UIConstants.menuDrawerLogoHeight)
            .contentShape(Rectangle())
        }
        .padding(.vertical, value: .regular)
        .padding(.leading, value: .medium)
        .padding(.trailing, value: .verySmall)
        .background(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)
        .clipped()
        .shadow(color: MailResourcesAsset.menuDrawerShadowColor.swiftUIColor, radius: 1, x: 0, y: 2)
    }
}

#Preview {
    MenuHeaderView()
}
