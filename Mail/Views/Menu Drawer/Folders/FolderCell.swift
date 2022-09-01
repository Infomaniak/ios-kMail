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
    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var mailboxManager: MailboxManager
    @EnvironmentObject var navigationDrawerController: NavigationDrawerController

    let folder: Folder
    var level = 0

    var isCompact: Bool

    @State private var shouldTransit = false

    var body: some View {
        Group {
            if isCompact {
                Button(action: updateFolder) {
                    FolderCellContent(folder: folder, level: level, selectedFolder: $splitViewManager.selectedFolder)
                }
            } else {
                NavigationLink(isActive: $shouldTransit) {
                    ThreadListManagerView(
                        mailboxManager: mailboxManager,
                        isCompact: isCompact
                    )
                } label: {
                    Button {
                        splitViewManager.selectedFolder = folder.thaw()
                        splitViewManager.showSearch = false
                        self.shouldTransit = true
                    } label: {
                        FolderCellContent(folder: folder, level: level, selectedFolder: $splitViewManager.selectedFolder)
                    }
                }
            }

            ForEach(folder.children) { child in
                FolderCell(folder: child, level: level + 1, isCompact: isCompact)
            }
        }
    }

    private func updateFolder() {
        splitViewManager.selectedFolder = folder.thaw()
        navigationDrawerController.close()
    }
}

struct FolderCellContent: View {
    let folder: Folder
    let level: Int
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
        .padding(.leading, Constants.menuDrawerSubFolderPadding * CGFloat(level))
        .padding(.trailing, 18)
        .background(SelectionBackground(isSelected: isSelected, offsetX: 10, leadingPadding: -2, verticalPadding: 0))
    }
}

struct FolderCellView_Previews: PreviewProvider {
    static var previews: some View {
        FolderCell(
            folder: PreviewHelper.sampleFolder,
            isCompact: false
        )
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environmentObject(NavigationDrawerController())
    }
}
