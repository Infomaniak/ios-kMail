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

extension AIEngineChoiceView {
    static let aiInformationBlock = InformationBlock(
        icon: MailResourcesAsset.info.swiftUIImage,
        message: MailResourcesStrings.Localizable.aiEngineWarning,
        iconTint: MailResourcesAsset.textSecondaryColor.swiftUIColor
    )
}

struct AIEngineChoiceView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(UserDefaults.shared.key(.aiEngine)) private var aiEngine = DefaultPreferences.aiEngine

    private let values = Array(AIEngine.allCases)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text(MailResourcesStrings.Localizable.settingsAiEngineDescription)
                        .textStyle(.bodyMedium)

                    ForEach(values, id: \.rawValue) { value in
                        SettingsOptionCell(value: value, isSelected: value == aiEngine, isLast: value == values.last) {
                            @InjectService var matomo: MatomoUtils
                            matomo.track(eventWithCategory: .promptAIEngine, name: value.matomoName)
                            aiEngine = value
                            dismiss()
                        }
                    }

                    InformationBlockView(Self.aiInformationBlock)

                    Text(MailResourcesStrings.Localizable.aiEngineChangeChoice)
                }
            }

            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismissAction: dismiss)
                }
            }
            .tint(MailResourcesAsset.aiColor.swiftUIColor)
        }
    }
}

#Preview {
    AIEngineChoiceView()
}
