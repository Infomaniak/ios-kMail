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
import MailCoreUI
import MailResources
import SwiftUI

struct AIEngineOptionView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @AppStorage(UserDefaults.shared.key(.aiEngine)) private var aiEngine = DefaultPreferences.aiEngine

    let matomoCategory: MatomoUtils.EventCategory
    var completionHandler: (() -> Void)?

    private let engines = Array(AIEngine.allCases)

    var body: some View {
        VStack(spacing: UIPadding.regular) {
            VStack(spacing: 0) {
                ForEach(engines, id: \.rawValue) { option in
                    SettingsOptionCell(value: option, isSelected: option == aiEngine, isLast: option == engines.last) {
                        matomo.track(eventWithCategory: matomoCategory, name: option.matomoName)
                        aiEngine = option
                        completionHandler?()
                    }
                }
            }

            InformationBlockView(
                icon: MailResourcesAsset.info.swiftUIImage,
                message: MailResourcesStrings.Localizable.aiEngineWarning,
                iconColor: MailResourcesAsset.textSecondaryColor.swiftUIColor
            )
            .padding(.horizontal, value: .regular)
        }
    }
}

#Preview {
    AIEngineOptionView(matomoCategory: .settingsAIEngine)
}
