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

struct SearchFilterFolderCell: View {
    var folders: [Folder]
    @Binding public var selectedFolderId: String

    init(selection: Binding<String>, folders: [Folder]) {
        self.folders = folders
        _selectedFolderId = selection
    }

    private var selectedFolderName: String {
        guard let folder = (folders.first { $0.remoteId == selectedFolderId }) else {
            return allFoldersItem.name
        }
        return folder.localizedName
    }

    private var isSelected: Bool {
        return selectedFolderId != allFoldersItem.id
    }

    private var allFoldersItem = (
        id: "",
        name: MailResourcesStrings.Localizable.searchFilterFolder,
        icon: MailResourcesAsset.allFolders.swiftUIImage
    )

    private var sortedFolders: [Folder] {
        return folders.sorted()
    }

    var body: some View {
        Menu {
            Picker(selection: $selectedFolderId.animation(), label: EmptyView()) {
                HStack {
                    allFoldersItem.icon
                    Text(allFoldersItem.name)
                }
                .tag(allFoldersItem.id)

                ForEach(sortedFolders) { folder in
                    HStack {
                        folder.icon
                        Text(folder.localizedName)
                    }
                    .tag(folder.remoteId)
                }
            }
        } label: {
            HStack(spacing: UIPadding.searchFolderCellSpacing) {
                if isSelected {
                    MailResourcesAsset.check.swiftUIImage
                        .resizable()
                        .frame(width: 12, height: 12)
                }
                Text(selectedFolderName)
                    .font(MailTextStyle.bodyMedium.font)
                ChevronIcon(style: .down, color: .accentColor)
            }
        }
        .filterCellStyle(isSelected: isSelected)
    }
}

struct SearchFilterFolderCell_Previews: PreviewProvider {
    static var previews: some View {
        SearchFilterFolderCell(selection: .constant("folder"), folders: [PreviewHelper.sampleFolder])
    }
}
