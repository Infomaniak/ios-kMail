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

struct ReplaceMessageContentView: View {
    @AppStorage(UserDefaults.shared.key(.showAIReplaceContentAlert)) private var showAIReplaceContentAlert = DefaultPreferences.showAIReplaceContentAlert

    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Détection d’un contenu déjà existant")
                .textStyle(.bodyMedium)
                .padding(.bottom, UIPadding.alertTitleBottom)

            VStack(spacing: UIPadding.medium) {
                Text("Voulez-vous remplacer le contenu existant par la proposition de l’assistant ?")
                    .textStyle(.bodySecondary)

                Toggle("Ne plus afficher ce message", isOn: $showAIReplaceContentAlert)
                    .toggleStyle(CheckmarkToggleStyle(tintColor: MailResourcesAsset.aiColor.swiftUIColor, textColor: MailResourcesAsset.textSecondaryColor.swiftUIColor))
            }
            .padding(.bottom, UIPadding.alertDescriptionBottom)

            ModalButtonsView(primaryButtonTitle: "Remplacer", primaryButtonAction: action)
        }
    }
}

struct ReplaceMessageContentView_Preview: PreviewProvider {
    static var previews: some View {
        ReplaceMessageContentView { /* Preview */ }
    }
}
