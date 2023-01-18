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

struct FolderCellTypeEnvironment: EnvironmentKey {
    static var defaultValue = FolderCell.CellType.link
}

extension EnvironmentValues {
    var folderCellType: FolderCell.CellType {
        get { self[FolderCellTypeEnvironment.self] }
        set { self[FolderCellTypeEnvironment.self] = newValue }
    }
}

struct FolderCell: View {
    enum CellType {
        case link, indicator
    }

    @Environment(\.folderCellType) var cellType

    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var mailboxManager: MailboxManager
    @EnvironmentObject var navigationDrawerState: NavigationDrawerState

    let folder: NestableFolder
    var level = 0

    var isCompact = true

    var customCompletion: ((Folder) -> Void)?

    @State private var shouldTransit = false

    private var isButtonDisabled: Bool {
        cellType == .indicator && folder.id == splitViewManager.selectedFolder?.id
    }

    var body: some View {
        Group {
            if cellType == .indicator || isCompact {
                Button(action: didTapButton) {
                    FolderCellContent(folder: folder.content, level: level, selectedFolder: $splitViewManager.selectedFolder)
                }
                .disabled(isButtonDisabled)
            } else {
                NavigationLink(isActive: $shouldTransit) {
                    ThreadListManagerView(
                        mailboxManager: mailboxManager,
                        isCompact: isCompact
                    )
                } label: {
                    Button {
                        splitViewManager.selectedFolder = folder.content
                        splitViewManager.showSearch = false
                        self.shouldTransit = true
                    } label: {
                        FolderCellContent(folder: folder.content, level: level, selectedFolder: $splitViewManager.selectedFolder)
                    }
                }
            }

            if level < Constants.menuDrawerMaximumSubfolderLevel {
                ForEach(folder.children) { child in
                    FolderCell(folder: child, level: level + 1, isCompact: isCompact)
                }
            }
        }
    }

    private func didTapButton() {
        if cellType == .indicator {
            customCompletion?(folder.content)
        } else {
            updateFolder()
        }
    }

    private func updateFolder() {
        splitViewManager.selectedFolder = folder.content
        navigationDrawerState.close()
    }
}

struct FolderCellContent: View {
    @Environment(\.folderCellType) var cellType

    let folder: Folder
    let level: Int
    @Binding var selectedFolder: Folder?

    private var isSelected: Bool {
        folder.id == selectedFolder?.id
    }

    private var textStyle: MailTextStyle {
        if cellType == .link {
            return isSelected ? .bodyMediumAccent : .bodyMedium
        }
        return .body
    }

    var body: some View {
        HStack(spacing: Constants.menuDrawerHorizontalItemSpacing) {
            folder.icon
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.accentColor)

            Text(folder.localizedName)
                .textStyle(textStyle)
                .lineLimit(1)

            Spacer()

            accessory
        }
        .padding(.vertical, 14)
        .padding(.horizontal, Constants.menuDrawerHorizontalPadding)
        .padding(.leading, Constants.menuDrawerSubFolderPadding * CGFloat(level))
        .background(background)
    }

    @ViewBuilder
    private var accessory: some View {
        if cellType == .link {
            Text(folder.formattedUnreadCount)
                .textStyle(.bodySmallMediumAccent)
        } else if isSelected {
            Image(resource: MailResourcesAsset.check)
                .resizable()
                .frame(width: 16, height: 16)
        }
    }

    @ViewBuilder
    private var background: some View {
        if cellType == .link {
            SelectionBackground(
                isSelected: isSelected,
                offsetX: 8,
                leadingPadding: 0,
                verticalPadding: 0,
                defaultColor: MailResourcesAsset.backgroundMenuDrawer.swiftUiColor
            )
        }
    }
}

struct FolderCellView_Previews: PreviewProvider {
    static var previews: some View {
        FolderCell(
            folder: NestableFolder(content: PreviewHelper.sampleFolder, children: []),
            isCompact: false
        )
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environmentObject(NavigationDrawerState())
    }
}
