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

import DesignSystem
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct PromptAIEngineOptionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: IKPadding.medium) {
                    Text(MailResourcesStrings.Localizable.settingsAiEngineDescription)
                        .textStyle(.bodyMedium)
                        .padding(.horizontal, value: .medium)

                    AIEngineOptionView(matomoCategory: .promptAIEngine) {
                        dismiss()
                    }
                }
            }
            .background(MailResourcesAsset.backgroundColor.swiftUIColor)
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
    PromptAIEngineOptionView()
}
