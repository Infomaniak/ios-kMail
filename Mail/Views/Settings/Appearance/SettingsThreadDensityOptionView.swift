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

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI
import UIKit

struct SettingsThreadDensityOptionView: View {
    @State private var selectedValue = UserDefaults.shared.threadDensity

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionTitleView(title: MailResourcesStrings.Localizable.settingsSelectDisplayModeDescription)

            Picker("Display mode", selection: $selectedValue.animation()) {
                ForEach(ThreadDensity.allCases, id: \.rawValue) { value in
                    Text(value.title)
                        .tag(value)
                }
            }
            .pickerStyle(.segmented)
            .ikSegmentedControl()
            .onChange(of: selectedValue) { newValue in
                @InjectService var matomo: MatomoUtils
                matomo.track(eventWithCategory: .settingsDensity, name: newValue.rawValue)
            }
            .padding([.horizontal, .top], value: .medium)
            .padding(.bottom, value: .large)

            selectedValue.image?
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 0)
                .padding(.horizontal, value: .medium)

            Spacer()
        }
        .onDisappear {
            UserDefaults.shared.threadDensity = selectedValue
        }
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsThreadListDensityTitle, displayMode: .inline)
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "ThreadDensity"])
    }
}

#Preview {
    SettingsThreadDensityOptionView()
}
