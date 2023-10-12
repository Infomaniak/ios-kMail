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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct FolderCellTypeEnvironment: EnvironmentKey {
    static var defaultValue = FolderCell.CellType.menuDrawer
}

extension EnvironmentValues {
    var folderCellType: FolderCell.CellType {
        get { self[FolderCellTypeEnvironment.self] }
        set { self[FolderCellTypeEnvironment.self] = newValue }
    }
}

struct FolderCell: View {
    enum CellType {
        case menuDrawer, move
    }

    @Environment(\.folderCellType) private var cellType
    @Environment(\.isCompactWindow) private var isCompactWindow

    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var navigationDrawerState: NavigationDrawerState

    let folder: NestableFolder
    var level = 0
    var currentFolderId: String?
    var canCollapseSubFolders = false
    var matomoCategory: MatomoUtils.EventCategory?
    var customCompletion: ((Folder) -> Void)?

    @State private var shouldTransit = false

    private var isCurrentFolder: Bool {
        folder.id == currentFolderId
    }

    var body: some View {
        Group {
            if cellType == .move || isCompactWindow {
                Button(action: didTapButton) {
                    FolderCellContent(folderPrimaryKey: folder.content.id,
                                      name: folder.content.name,
                                      localizedName: folder.content.localizedName,
                                      isExpanded: folder.content.isExpanded,
                                      isChildrenEmpty: folder.content.children.isEmpty,
                                      formattedUnreadCount: folder.content.formattedUnreadCount,
                                      remoteUnreadCount: folder.content.remoteUnreadCount,
                                      icon: folder.content.icon,
                                      role: folder.content.role,
                                      level: level,
                                      isCurrentFolder: isCurrentFolder,
                                      canCollapseSubFolders: canCollapseSubFolders)
                }
            } else {
                NavigationLink(isActive: $shouldTransit) {
                    ThreadListManagerView()
                } label: {
                    Button {
                        if let matomoCategory {
                            @InjectService var matomo: MatomoUtils
                            matomo.track(eventWithCategory: matomoCategory, name: folder.content.matomoName)
                        }
                        splitViewManager.selectedFolder = folder.content
                        splitViewManager.showSearch = false
                        shouldTransit = true
                    } label: {
                        FolderCellContent(folderPrimaryKey: folder.content.id,
                                          name: folder.content.name,
                                          localizedName: folder.content.localizedName,
                                          isExpanded: folder.content.isExpanded,
                                          isChildrenEmpty: folder.content.children.isEmpty,
                                          formattedUnreadCount: folder.content.formattedUnreadCount,
                                          remoteUnreadCount: folder.content.remoteUnreadCount,
                                          icon: folder.content.icon,
                                          role: folder.content.role,
                                          level: level,
                                          isCurrentFolder: isCurrentFolder,
                                          canCollapseSubFolders: canCollapseSubFolders)
                    }
                }
            }

            if !folder.content.isInvalidated && folder.content.isExpanded || cellType == .move {
                ForEach(folder.displayableChildren) { child in
                    FolderCell(
                        folder: child,
                        level: level + 1,
                        currentFolderId: currentFolderId,
                        canCollapseSubFolders: canCollapseSubFolders,
                        customCompletion: customCompletion
                    )
                }
            }
        }
    }

    private func didTapButton() {
        if cellType == .move {
            customCompletion?(folder.content)
        } else {
            updateFolder()
        }
    }

    private func updateFolder() {
        if let matomoCategory {
            @InjectService var matomo: MatomoUtils
            matomo.track(eventWithCategory: matomoCategory, name: folder.content.matomoName)
        }
        splitViewManager.selectedFolder = folder.content
        navigationDrawerState.close()
    }
}

struct FolderCellView_Previews: PreviewProvider {
    static var previews: some View {
        FolderCell(folder: NestableFolder(content: PreviewHelper.sampleFolder, children: []), currentFolderId: nil)
            .environmentObject(PreviewHelper.sampleMailboxManager)
            .environmentObject(NavigationDrawerState())
    }
}
