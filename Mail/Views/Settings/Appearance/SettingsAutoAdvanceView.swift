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

enum AutoAdvanceSection: CaseIterable {
    case compact
    case large

    var options: [AutoAdvance] {
        switch self {
        case .compact:
            return [.previousThread, .followingThread, .listOfThread]
        case .large:
            return [.previousThread, .followingThread]
        }
    }
}

struct SettingsAutoAdvanceView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @AppStorage(UserDefaults.shared.key(.autoAdvance)) private var autoAdvance = DefaultPreferences.autoAdvance

    var completionHandler: (() -> Void)?

    var section: AutoAdvanceSection

    var body: some View {
        ScrollView {
            SettingsSectionTitleView(title: MailResourcesStrings.Localizable.settingsAutoAdvanceDescription)

            ForEach(section.options, id: \.rawValue) { option in
                SettingsOptionCell(value: option, isSelected: option == autoAdvance, isLast: option == section.options.last) {
                    matomo.track(eventWithCategory: .settingsAutoAdvance, name: option.rawValue)
                    autoAdvance = option
                    completionHandler?()
                }
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationTitle(MailResourcesStrings.Localizable.settingsAutoAdvanceTitle)
    }
}

#Preview {
    SettingsAutoAdvanceView(section: .compact)
}
