/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import InfomaniakCoreUI
import MailCore
import MailCoreUI
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
            Button {
                withAnimation {
                    selectedFolderId = allFoldersItem.id
                }
            } label: {
                HStack {
                    allFoldersItem.icon
                    Text(allFoldersItem.name)
                }
            }

            ForEach(sortedFolders) { folder in
                Button {
                    withAnimation {
                        selectedFolderId = folder.remoteId
                    }
                } label: {
                    HStack {
                        folder.icon
                        Text(folder.localizedName)
                    }
                }
            }
        } label: {
            HStack(spacing: IKPadding.searchFolderCellSpacing) {
                if isSelected {
                    MailResourcesAsset.check
                        .iconSize(.small)
                }
                Text(selectedFolderName)
                    .font(MailTextStyle.bodyMedium.font)
                ChevronIcon(direction: .down, shapeStyle: HierarchicalShapeStyle.primary)
            }
        }
        .filterCellStyle(isSelected: isSelected)
    }
}

#Preview {
    SearchFilterFolderCell(selection: .constant("folder"), folders: [PreviewHelper.sampleFolder])
}
