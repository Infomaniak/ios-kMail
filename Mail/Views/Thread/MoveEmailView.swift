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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct MoveAction: Identifiable {
    var id: String {
        return "\(target.id)\(fromFolderId ?? "")"
    }

    let fromFolderId: String?
    let target: ActionsTarget
}

struct MoveEmailView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.dismissModal) var dismissModal

    @EnvironmentObject private var mailboxManager: MailboxManager

    typealias MoveHandler = (Folder) -> Void

    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.role != .draft && $0.toolType == nil }) var folders
    @State private var isShowingCreateFolderAlert = false

    private var filteredFolders: [NestableFolder] {
        guard !searchFilter.isEmpty else {
            return NestableFolder.createFoldersHierarchy(from: Array(folders.where { $0.parents.count == 0 }))
        }
        return folders.filter {
            let filter = searchFilter.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            return $0.verifyFilter(filter)
        }.map { NestableFolder(content: $0, children: []) }
    }

    @State private var searchFilter = ""

    let moveAction: MoveAction

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                listOfFolders(nestableFolders: filteredFolders.filter { $0.content.role != nil })
                if searchFilter.isEmpty {
                    IKDivider(horizontalPadding: 8)
                }
                listOfFolders(nestableFolders: filteredFolders.filter { $0.content.role == nil })
            }
            .searchable(text: $searchFilter, placement: .navigationBarDrawer(displayMode: .always))
        }
        .navigationTitle(MailResourcesStrings.Localizable.actionMove)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    matomo.track(eventWithCategory: .createFolder, name: "fromMove")
                    isShowingCreateFolderAlert.toggle()
                } label: {
                    MailResourcesAsset.folderAdd.swiftUIImage
                }
            }
        }
        .environment(\.folderCellType, .indicator)
        .matomoView(view: ["MoveEmailView"])
        .customAlert(isPresented: $isShowingCreateFolderAlert) {
            CreateFolderView(mode: .move { newFolder in
                Task {
                    try await ActionUtils(actionsTarget: moveAction.target, mailboxManager: mailboxManager).move(to: newFolder)
                }
                dismissModal()
            })
        }
    }

    private func listOfFolders(nestableFolders: [NestableFolder]) -> some View {
        ForEach(nestableFolders) { nestableFolder in
            FolderCell(folder: nestableFolder, currentFolderId: moveAction.fromFolderId) { folder in
                Task {
                    try await ActionUtils(actionsTarget: moveAction.target, mailboxManager: mailboxManager).move(to: folder)
                }
                dismissModal()
            }
        }
    }
}

struct MoveMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MoveEmailView(moveAction: MoveAction(fromFolderId: PreviewHelper.sampleFolder.id,
                                             target: .message(PreviewHelper.sampleMessage)))
            .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
