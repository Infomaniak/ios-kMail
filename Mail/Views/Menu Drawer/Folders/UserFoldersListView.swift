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
import SwiftUI
import UIKit

struct UserFoldersListView: View {
    @ObservedResults(Folder.self) var folders

    @State private var isExpanded = false
    @Binding var selectedFolder: Folder?

    var isCompact: Bool

    private let foldersSortDescriptors = [
        SortDescriptor(keyPath: \Folder.isFavorite, ascending: false),
        SortDescriptor(keyPath: \Folder.unreadCount, ascending: false),
        SortDescriptor(keyPath: \Folder.name)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(MailResourcesStrings.Localizable.buttonFolders)
                        .textStyle(.body)
                    Spacer()
                    ChevronIcon(style: isExpanded ? .up : .down)
                }
            }
            .padding(.leading, Constants.menuDrawerHorizontalPadding)
            .padding(.trailing, 18)

            if isExpanded {
                Spacer(minLength: Constants.menuDrawerVerticalPadding)

                ForEach(folders.sorted(by: foldersSortDescriptors).filter { $0.role == nil }) { folder in
                    FolderCell(folder: folder, selectedFolder: $selectedFolder, isCompact: isCompact)
                }

                MenuDrawerItemCell(content: .init(icon: MailResourcesAsset.add, label: MailResourcesStrings.Localizable.buttonCreateFolder) {
                    // TODO: Create folder
                })
                .padding(.top, Constants.menuDrawerVerticalPadding)
                .padding([.leading, .trailing], Constants.menuDrawerHorizontalPadding)
            }
        }
        .padding([.top, .bottom], 19)
    }
}
