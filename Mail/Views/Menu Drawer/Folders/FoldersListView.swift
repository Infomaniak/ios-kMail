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

import InfomaniakCore
import InfomaniakCoreUI
import MailCore
import RealmSwift
import SwiftUI

struct FoldersListView: View {
    @EnvironmentObject private var mainViewState: MainViewState

    private let folders: [NestableFolder]
    private let hasSubFolders: Bool

    init(folders: [NestableFolder]) {
        self.folders = folders
        hasSubFolders = folders.contains { !$0.children.isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(folders) { folder in
                FolderCell(folder: folder,
                           currentFolderId: mainViewState.selectedFolder.remoteId,
                           canCollapseSubFolders: hasSubFolders,
                           matomoCategory: .menuDrawer)
            }
        }
    }
}
