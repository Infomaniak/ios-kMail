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

struct AIPropositionMenu: View {
    struct AIAction: Identifiable {
        let id: Int
        let label: String
        let icon: MailResourcesImages

        static let modify = AIAction(id: 1, label: "Modifier ma demande", icon: MailResourcesAsset.pencil)
        static let regenerate = AIAction(id: 2, label: "Regénérer une réponse", icon: MailResourcesAsset.fileRegenerate)
        static let shorten = AIAction(id: 3, label: "Raccourcir", icon: MailResourcesAsset.shortenParagraph)
        static let extend = AIAction(id: 4, label: "Rallonger", icon: MailResourcesAsset.expandParagraph)
        static let seriousWriting = AIAction(id: 5, label: "Rédaction sériseuse", icon: MailResourcesAsset.briefcase)
        static let friendlyWriting = AIAction(id: 6, label: "Rédaction amicale", icon: MailResourcesAsset.smiley)

        static let allActions: [[Self]] = [[.modify, .regenerate], [.shorten, .extend], [.seriousWriting, .friendlyWriting]]
    }

    var body: some View {
        Menu {
            ForEach(AIAction.allActions.indices, id: \.self) { actionsGroupIndex in
                let actionsGroup = AIAction.allActions[actionsGroupIndex]
                Section {
                    ForEach(actionsGroup) { action in
                        Button {
                            handleAction(action)
                        } label: {
                            Label(action.label, image: action.icon.name)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: UIPadding.small) {
                MailResourcesAsset.pencil.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(MailResourcesStrings.Localizable.aiButtonRefine)
            }
            .frame(height: UIConstants.buttonMediumHeight)
        }
        .tint(MailResourcesAsset.textSecondaryColor.swiftUIColor)
        .modifier(FixedMenuOrderModifier())
    }

    private func handleAction(_ action: AIAction) {
        // TODO: Handle action
    }
}

struct FixedMenuOrderModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .menuOrder(.fixed)
        } else {
            content
        }
    }
}

struct AIPropositionMenu_Preview: PreviewProvider {
    static var previews: some View {
        AIPropositionMenu()
    }
}
