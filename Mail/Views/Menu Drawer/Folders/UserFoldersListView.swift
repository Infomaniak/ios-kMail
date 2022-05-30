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
import MailCore
import MailResources
import RealmSwift
import UIKit
import SwiftUI

struct UserFoldersListView: View {
    @ObservedResults(Folder.self) var folders

    @State private var unfoldFolders = false
    @Binding var selectedFolder: Folder?

    var isCompact: Bool

    private let foldersSortDescriptors = [
        SortDescriptor(keyPath: \Folder.isFavorite, ascending: false),
        SortDescriptor(keyPath: \Folder.unreadCount, ascending: false),
        SortDescriptor(keyPath: \Folder.name)
    ]

    var body: some View {
        DisclosureGroup(MailResourcesStrings.buttonFolders, isExpanded: $unfoldFolders) {
            VStack {
                ForEach(AnyRealmCollection(folders.sorted(by: foldersSortDescriptors)).filter { $0.role == nil }) { folder in
                    FolderCell(currentFolder: folder, selectedFolder: $selectedFolder, isCompact: isCompact)
                    .padding([.top, .bottom], Constants.menuDrawerFolderCellPadding)
                }
                .accentColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
            }
            .padding(.top, 9)
        }
        .accentColor(Color(MailResourcesAsset.primaryTextColor.color))
    }
}
