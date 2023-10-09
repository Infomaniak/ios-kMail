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

struct AIPropositionMenu: View {
    static let allShortcuts: [[AIShortcutAction]] = [
        [.edit, .regenerate],
        [.shorten, .expand],
        [.seriousWriting, .friendlyWriting]
    ]

    @LazyInjectService private var matomo: MatomoUtils

    @ObservedObject var aiModel: AIModel

    var body: some View {
        Menu {
            ForEach(Self.allShortcuts.indices, id: \.self) { actionsGroupIndex in
                let actionsGroup = Self.allShortcuts[actionsGroupIndex]
                Section {
                    ForEach(actionsGroup) { action in
                        Button {
                            matomo.track(eventWithCategory: .aiWriter, name: action.matomoName)
                            Task {
                                await aiModel.executeShortcut(action)
                            }
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
                    .frame(width: 24, height: 24)
                Text(MailResourcesStrings.Localizable.aiButtonRefine)
            }
        }
        .simultaneousGesture(TapGesture().onEnded {
            matomo.track(eventWithCategory: .aiWriter, name: "refine")
        })
        .tint(MailResourcesAsset.textSecondaryColor.swiftUIColor)
        .modifier(FixedMenuOrderModifier())
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
        AIPropositionMenu(aiModel: AIModel(mailboxManager: PreviewHelper.sampleMailboxManager))
    }
}
