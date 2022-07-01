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

    let folder: Folder
    @Binding var selectedFolder: Folder?

    var isCompact: Bool

    var body: some View {
        if isCompact {
            Button(action: updateFolder) {
                FolderCellContent(folder: folder, selectedFolder: $selectedFolder)
            }
        } else {
            NavigationLink {
                ThreadListView(mailboxManager: mailboxManager, folder: .constant(folder), isCompact: isCompact)
                    .onAppear { selectedFolder = folder }
            } label: {
                FolderCellContent(folder: folder, selectedFolder: $selectedFolder)
            }
        }
    }

    private func updateFolder() {
        selectedFolder = folder
        navigationDrawerController.close()
    }
}

struct FolderCellContent: View {
    let folder: Folder
    @Binding var selectedFolder: Folder?

    private var isSelected: Bool {
        folder.id == selectedFolder?.id
    }

    private var textStyle: MailTextStyle {
        isSelected ? .button : .body
    }

    var body: some View {
        HStack(spacing: 0) {
            folder.icon
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.accentColor)
                .padding(.trailing, 24)

            Text(folder.localizedName)
                .textStyle(textStyle)

            Spacer()

            if folder.unreadCount != nil {
                Text(folder.formattedUnreadCount)
                    .textStyle(.calloutHighlighted)
            }
        }
        .padding(.vertical, Constants.menuDrawerVerticalPadding)
        .padding(.leading, Constants.menuDrawerHorizontalPadding)
        .padding(.trailing, 18)
        .modifyIf(isSelected) { view in
            view
                .background(SelectionBackground())
        }
    }
}

struct FolderCellView_Previews: PreviewProvider {
    static var previews: some View {
        FolderCell(
            folder: PreviewHelper.sampleFolder,
            selectedFolder: .constant(PreviewHelper.sampleFolder),
            isCompact: false
        )
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environmentObject(NavigationDrawerController())
    }
}
