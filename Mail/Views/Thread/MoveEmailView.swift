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

struct MoveEmailView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.dismissModal) var dismissModal

    @EnvironmentObject private var actionsManager: ActionsManager

    typealias MoveHandler = (Folder) -> Void

    @ObservedResults(Folder.self, where: { $0.role != .draft && $0.toolType == nil }) var folders
    @State private var isShowingCreateFolderAlert = false

    private var filteredFolders: [NestableFolder] {
        guard !searchFilter.isEmpty else {
            // swiftlint:disable:next empty_count
            return NestableFolder.createFoldersHierarchy(from: Array(folders.where { $0.parents.count == 0 }))
        }
        return folders.filter {
            let filter = searchFilter.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            return $0.verifyFilter(filter)
        }.map { NestableFolder(content: $0, children: []) }
    }

    @State private var searchFilter = ""

    let movedMessages: [Message]
    let originFolder: Folder?

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
        .environment(\.folderCellType, .move)
        .matomoView(view: ["MoveEmailView"])
        .customAlert(isPresented: $isShowingCreateFolderAlert) {
            CreateFolderView(mode: .move { newFolder in
                move(to: newFolder)
            })
        }
    }

    private func move(to folder: Folder) {
        Task {
            try await actionsManager.performMove(messages: movedMessages, from: originFolder, to: folder)
        }
        dismissModal()
    }

    private func listOfFolders(nestableFolders: [NestableFolder]) -> some View {
        ForEach(nestableFolders) { nestableFolder in
            FolderCell(folder: nestableFolder, currentFolderId: movedMessages.first?.folderId) { folder in
                move(to: folder)
            }
        }
    }
}

struct MoveMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MoveEmailView(movedMessages: [PreviewHelper.sampleMessage], originFolder: nil)
            .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
