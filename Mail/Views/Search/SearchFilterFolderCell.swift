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
        guard let folder = (folders.first { $0.id == selectedFolderId }) else {
            return allFoldersItem.name
        }
        return folder.localizedName
    }

    private var isSelected: Bool {
        return selectedFolderId != allFoldersItem.id
    }

    private var allFoldersItem = (id: "", name: MailResourcesStrings.Localizable.searchFilterFolder, icon: MailResourcesAsset.folder.image)

    private var sortedFolders: [Folder] {
        return folders.sorted()
    }

    var body: some View {
        Menu {
            Picker(selection: $selectedFolderId.animation(), label: EmptyView()) {
                Text(allFoldersItem.name)
                    .tag(allFoldersItem.id)
                ForEach(sortedFolders) { folder in
                    HStack {
                        folder.icon
                        Text(folder.formattedPath)
                    }
                    .tag(folder.id)
                }
            }
        } label: {
            HStack(spacing: 11) {
                if isSelected {
                    Image(resource: MailResourcesAsset.check)
                        .resizable()
                        .frame(width: 13, height: 13)
                }
                Text(selectedFolderName)
                    .font(MailTextStyle.bodyMedium.font)
                Image(resource: MailResourcesAsset.arrowDown)
                    .resizable()
                    .frame(width: 13, height: 13)
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
