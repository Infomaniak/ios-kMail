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
import SwiftUI

struct FolderCell: View {
    @EnvironmentObject var mailboxManager: MailboxManager
    @EnvironmentObject var navigationDrawerController: NavigationDrawerController

    @State var currentFolder: Folder!
    @Binding var selectedFolder: Folder?

    var isCompact: Bool

    var body: some View {
        if isCompact {
            Button(action: updateFolder) {
                FolderCellContent(currentFolder: $currentFolder, selectedFolder: $selectedFolder)
            }
        } else {
            NavigationLink {
                ThreadListView(mailboxManager: mailboxManager, folder: $currentFolder, isCompact: isCompact)
                    .onAppear { selectedFolder = currentFolder }
            } label: {
                FolderCellContent(currentFolder: $currentFolder, selectedFolder: $selectedFolder)
            }
        }
    }

    private func updateFolder() {
        selectedFolder = currentFolder
        navigationDrawerController.close()
    }
}

struct FolderCellContent: View {
    @Binding var currentFolder: Folder!
    @Binding var selectedFolder: Folder?

    private var iconSize: CGFloat {
        if currentFolder.role == nil {
            return currentFolder.isFavorite ? 22 : 19
        }
        return 24
    }

    private var isSelected: Bool {
        currentFolder.id == selectedFolder?.id
    }

    private var textStyle: MailTextStyle {
        isSelected ? .button : .body
    }

    var body: some View {
        HStack {
            currentFolder.icon
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(.accentColor)
                .padding(.trailing, 10)

            Text(currentFolder.localizedName)
                .textStyle(textStyle)

            Spacer()

            if currentFolder.unreadCount != nil {
                Text(currentFolder.formattedUnreadCount)
                    .textStyle(.calloutHighlighted)
            }
        }
    }
}

struct FolderCellView_Previews: PreviewProvider {
    static var previews: some View {
        FolderCell(
            currentFolder: PreviewHelper.sampleFolder,
            selectedFolder: .constant(PreviewHelper.sampleFolder),
            isCompact: false
        )
        .previewLayout(.sizeThatFits)
        .previewDevice(PreviewDevice(stringLiteral: "iPhone 11 Pro"))
    }
}
