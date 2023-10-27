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

struct AIEngineChoiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: UIPadding.regular) {
                    Text(MailResourcesStrings.Localizable.settingsAiEngineDescription)
                        .textStyle(.bodyMedium)
                        .padding(.horizontal, value: .regular)

                    AIEngineOptionView(matomoCategory: .promptAIEngine) {
                        dismiss()
                    }

                    Text(MailResourcesStrings.Localizable.aiEngineChangeChoice)
                        .textStyle(.body)
                        .padding(.horizontal, value: .regular)
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
