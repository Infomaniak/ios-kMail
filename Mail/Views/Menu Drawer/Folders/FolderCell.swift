/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftModalPresentation
import SwiftUI

extension EnvironmentValues {
    @Entry
    var folderCellType = FolderCell.CellType.menuDrawer
}

struct FolderCell: View {
    enum CellType {
        case menuDrawer, move
    }

    @Environment(\.folderCellType) private var cellType
    @Environment(\.isCompactWindow) private var isCompactWindow

    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var navigationDrawerState: NavigationDrawerState

    let folder: NestableFolder
    var level = 0
    var currentFolderId: String?
    var matomoCategory: MatomoUtils.EventCategory?
    var customCompletion: ((Folder) -> Void)?

    @State private var shouldTransit = false

    private var isCurrentFolder: Bool {
        folder.frozenContent.remoteId == currentFolderId
    }

    var body: some View {
        Group {
            if cellType == .move || isCompactWindow {
                Button(action: didTapButton) {
                    FolderCellContent(
                        frozenFolder: folder.frozenContent,
                        level: level,
                        isCurrentFolder: isCurrentFolder
                    )
                }
                .accessibilityAction(.default) {
                    didTapButton()
                }
            } else {
                NavigationLink(isActive: $shouldTransit) {
                    ThreadListManagerView()
                } label: {
                    Button {
                        @InjectService var matomo: MatomoUtils
                        if let matomoCategory {
                            matomo.track(eventWithCategory: matomoCategory, name: folder.frozenContent.matomoName)
                        }
                        mainViewState.selectedFolder = folder.frozenContent
                        mainViewState.isShowingSearch = false
                        shouldTransit = true
                    } label: {
                        FolderCellContent(
                            frozenFolder: folder.frozenContent,
                            level: level,
                            isCurrentFolder: isCurrentFolder
                        )
                    }
                }
                .accessibilityAction(.default) {
                    updateFolder()
                }
            }

            if (folder.frozenContent.isExpanded && folder.frozenContent.hasSubFolders) || cellType == .move {
                ForEach(folder.children) { child in
                    if child.frozenContent.role == nil {
                        FolderCell(
                            folder: child,
                            level: level + 1,
                            currentFolderId: currentFolderId,
                            customCompletion: customCompletion
                        )
                    }
                }
            }
        }
    }

    private func didTapButton() {
        if cellType == .move {
            customCompletion?(folder.frozenContent)
        } else {
            updateFolder()
        }
    }

    private func updateFolder() {
        @InjectService var matomo: MatomoUtils
        if let matomoCategory {
            matomo.track(eventWithCategory: matomoCategory, name: folder.frozenContent.matomoName)
        }
        mainViewState.selectedFolder = folder.frozenContent
        navigationDrawerState.close()
    }
}

#Preview {
    FolderCell(folder: NestableFolder(content: PreviewHelper.sampleFolder, children: []), currentFolderId: nil)
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environmentObject(NavigationDrawerState())
}
