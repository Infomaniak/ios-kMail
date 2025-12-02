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

import SwiftUI
import MailResources

struct SearchFilterFolderCellSheetView: View {
    @ObservedObject var viewModel: FolderListViewModel

    @Binding var isPresented: Bool
    @Binding var selectedFolderId: String

    let allFoldersItem = (
        id: "",
        name: MailResourcesStrings.Localizable.searchFilterFolder,
        icon: MailResourcesAsset.allFolders.swiftUIImage
    )

    var body: some View {
        SearchableFolderListView(
            viewModel: viewModel,
            originFolderId: selectedFolderId
        ) { folder in
            changeSelectedFolderId(folderId: folder.remoteId)
        }
        .navigationTitle(MailResourcesStrings.Localizable.searchFolderName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    changeSelectedFolderId()
                } label: {
                    Label { Text(allFoldersItem.name) } icon: { allFoldersItem.icon }
                }
            }
        }
        .matomoView(view: ["SearchFilterFolderCellSheetView"])
        .sheetViewStyle()
    }

    private func changeSelectedFolderId(folderId: String = "") {
        selectedFolderId = folderId
        isPresented = false
    }
}
