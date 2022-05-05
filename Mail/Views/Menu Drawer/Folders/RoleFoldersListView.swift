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
import RealmSwift
import SwiftUI

struct RoleFoldersListView: View {
    @ObservedResults(Folder.self) var folders

    @Binding var selectedFolder: Folder?

    var isCompact: Bool
    let geometryProxy: GeometryProxy

    var body: some View {
        ForEach(AnyRealmCollection(folders).filter { $0.role != nil }.sorted()) { folder in
            FolderCell(currentFolder: folder, selectedFolder: $selectedFolder, isCompact: isCompact, geometryProxy: geometryProxy)
                .padding(.top, folder.role == .inbox ? 3 : Constants.menuDrawerFolderCellPadding)
                .padding(.bottom, folder.role == .inbox ? 0 : Constants.menuDrawerFolderCellPadding)

            if folder.role == .inbox {
                SeparatorView()
            }
        }
    }
}
