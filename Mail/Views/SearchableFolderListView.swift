/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import MailCore
import MailCoreUI
import SwiftUI

struct SearchableFolderListView: View {
    @ObservedObject var viewModel: FolderListViewModel

    let originFolderId: String?
    let customCompletion: (Folder) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                listOfFolders(nestableFolders: viewModel.roleFolders)
                if !viewModel.isSearching && !viewModel.userFolders.isEmpty {
                    IKDivider()
                }
                listOfFolders(nestableFolders: viewModel.userFolders)
            }
            .searchable(text: $viewModel.searchQuery)
        }
        .environment(\.folderCellType, .move)
    }

    private func listOfFolders(nestableFolders: [NestableFolder]) -> some View {
        ForEach(nestableFolders) { nestableFolder in
            FolderCell(folder: nestableFolder, currentFolderId: originFolderId, customCompletion: customCompletion)
        }
    }
}
