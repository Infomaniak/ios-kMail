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

struct AIShortcutAction: Identifiable, Equatable {
    let id: Int
    let label: String
    let icon: MailResourcesImages
    let apiName: String

    static let edit = AIShortcutAction(
        id: 1,
        label: MailResourcesStrings.Localizable.aiMenuEditRequest,
        icon: MailResourcesAsset.pencil,
        apiName: "edit"
    )
    static let regenerate = AIShortcutAction(
        id: 2,
        label: MailResourcesStrings.Localizable.aiMenuRegenerate,
        icon: MailResourcesAsset.fileRegenerate,
        apiName: "redraw"
    )
    static let shorten = AIShortcutAction(
        id: 3,
        label: MailResourcesStrings.Localizable.aiMenuShorten,
        icon: MailResourcesAsset.shortenParagraph,
        apiName: "shorten"
    )
    static let expand = AIShortcutAction(
        id: 4,
        label: MailResourcesStrings.Localizable.aiMenuExpand,
        icon: MailResourcesAsset.expandParagraph,
        apiName: "develop"
    )
    static let seriousWriting = AIShortcutAction(
        id: 5,
        label: MailResourcesStrings.Localizable.aiMenuSeriousWriting,
        icon: MailResourcesAsset.briefcase,
        apiName: "tune-professional"
    )
    static let friendlyWriting = AIShortcutAction(
        id: 6,
        label: MailResourcesStrings.Localizable.aiMenuFriendlyWriting,
        icon: MailResourcesAsset.smiley,
        apiName: "tune-friendly"
    )

    static func == (lhs: AIShortcutAction, rhs: AIShortcutAction) -> Bool {
        return lhs.id == rhs.id
    }
}

struct AIPropositionMenu: View {
    static let allShortcuts: [[AIShortcutAction]] = [
        [.edit, .regenerate],
        [.shorten, .expand],
        [.seriousWriting, .friendlyWriting]
    ]

    @ObservedObject var aiModel: AIModel

    let mailboxManager: MailboxManager

    var body: some View {
        Menu {
            ForEach(Self.allShortcuts.indices, id: \.self) { actionsGroupIndex in
                let actionsGroup = Self.allShortcuts[actionsGroupIndex]
                Section {
                    ForEach(actionsGroup) { action in
                        Button {
                            handleShortcut(action)
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

    private func handleShortcut(_ shortcut: AIShortcutAction) {
        switch shortcut {
        case .edit:
            aiModel.conversation.append(AIMessage(type: .assistant, content: MailResourcesStrings.Localizable.aiMenuEditRequest))
            aiModel.displayView(.prompt)
        default:
            aiModel.isLoading = true
            Task {
                guard let contextId = aiModel.contextId else { return }
                let response = try await mailboxManager.apiFetcher.aiShortcut(contextId: contextId, shortcut: shortcut.apiName)
                aiModel.conversation.append(contentsOf: [response.action, AIMessage(type: .assistant, content: response.content)])
                aiModel.isLoading = false
            }
        }
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
        AIPropositionMenu(aiModel: AIModel(), mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
