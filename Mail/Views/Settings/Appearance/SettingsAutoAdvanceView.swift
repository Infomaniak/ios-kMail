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

import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct SettingsAutoAdvanceView: View {
    @AppStorage(UserDefaults.shared.key(.autoAdvance)) private var autoAdvance = DefaultPreferences.autoAdvance

    var body: some View {
        VStack {
            List {
                SettingsSectionTitleView(title: MailResourcesStrings.Localizable.settingsAutoAdvanceDescription)
                    .settingsCell()

                ForEach(AutoAdvance.allCases, id: \.rawValue) { option in
                    SettingsOptionCell(
                        value: option,
                        isSelected: option == autoAdvance,
                        isLast: option == AutoAdvance.allCases.last
                    ) {
                        @InjectService var matomo: MatomoUtils
                        matomo.track(eventWithCategory: .settingsAutoAdvance, name: option.rawValue)
                        autoAdvance = option
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationTitle(MailResourcesStrings.Localizable.settingsAutoAdvanceTitle)
    }
}

#Preview {
    SettingsAutoAdvanceView()
}
