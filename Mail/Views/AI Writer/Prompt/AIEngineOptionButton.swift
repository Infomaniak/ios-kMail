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

struct AIEngineOptionButton: View {
    @AppStorage(UserDefaults.shared.key(.aiEngine)) private var aiEngine = DefaultPreferences.aiEngine

    @Binding var isShowingAIEngineChoice: Bool

    var body: some View {
        Button {
            @InjectService var matomo: MatomoUtils
            matomo.track(eventWithCategory: .promptAIEngine, name: "openEngineChoice")

            isShowingAIEngineChoice = true
        } label: {
            HStack(spacing: UIPadding.small) {
                Text(MailResourcesStrings.Localizable.aiGenerationTitlePrompt)
                    .foregroundColor(MailResourcesAsset.textPrimaryColor.swiftUIColor)

                if let image = aiEngine.image {
                    image
                }

                ChevronIcon(style: .right, color: MailResourcesAsset.textPrimaryColor.swiftUIColor)
            }
        }
    }
}

#Preview {
    AIEngineOptionButton(isShowingAIEngineChoice: .constant(false))
}