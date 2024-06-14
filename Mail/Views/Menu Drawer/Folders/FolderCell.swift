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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI
import SwiftUIMacros

extension EnvironmentValues {
    @EnvironmentValue
    var folderCellType = FolderCell.CellType.menuDrawer
}

struct FolderCell: View {
    @LazyInjectService private var matomo: MatomoUtils

    enum CellType {
        case menuDrawer, move
    }

    @Environment(\.folderCellType) private var cellType
    @Environment(\.isCompactWindow) private var isCompactWindow

    @EnvironmentObject var mainViewState: MainViewState
    @EnvironmentObject var navigationDrawerState: NavigationDrawerState

    let folder: NestableFolder
    var level = 0
    var currentFolderId: String?
    var canCollapseSubFolders = false
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
                        isCurrentFolder: isCurrentFolder,
                        canCollapseSubFolders: canCollapseSubFolders
                    )
                }
            } else {
                NavigationLink(isActive: $shouldTransit) {
                    ThreadListManagerView()
                } label: {
                    Button {
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
                            isCurrentFolder: isCurrentFolder,
                            canCollapseSubFolders: canCollapseSubFolders
                        )
                    }
                }
            }

            if folder.frozenContent.isExpanded || cellType == .move {
                ForEach(folder.children) { child in
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
            customCompletion?(folder.frozenContent)
        } else {
            updateFolder()
        }
    }

    private func updateFolder() {
        if let matomoCategory {
            matomo.track(eventWithCategory: matomoCategory, name: folder.frozenContent.matomoName)
        }
        mainViewState.selectedFolder = folder.frozenContent
        navigationDrawerState.close()
    }
}

struct FolderCellContent: View {
    @LazyInjectService private var matomo: MatomoUtils

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @Environment(\.folderCellType) var cellType

    private let frozenFolder: Folder
    private let level: Int
    private let isCurrentFolder: Bool
    private let canCollapseSubFolders: Bool

    private var textStyle: MailTextStyle {
        if cellType == .menuDrawer {
            return isCurrentFolder ? .bodyMediumAccent : .bodyMedium
        }
        return .body
    }

    private var canHaveChevron: Bool {
        canCollapseSubFolders && cellType == .menuDrawer
    }

    init(frozenFolder: Folder, level: Int, isCurrentFolder: Bool, canCollapseSubFolders: Bool = false) {
        assert(frozenFolder.isFrozen, "expecting frozenFolder to be frozen")
        self.frozenFolder = frozenFolder
        self.level = min(level, UIConstants.menuDrawerMaximumSubFolderLevel)
        self.isCurrentFolder = isCurrentFolder
        self.canCollapseSubFolders = canCollapseSubFolders
    }

    var body: some View {
        HStack(spacing: 0) {
            if canHaveChevron {
                Button(action: collapseFolder) {
                    ChevronIcon(direction: frozenFolder.isExpanded ? .up : .down)
                        .padding(value: .regular)
                }
                .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonExpandFolder(frozenFolder.name))
                .opacity(level == 0 && !frozenFolder.children.isEmpty ? 1 : 0)
            }

            HStack(spacing: UIPadding.menuDrawerCellSpacing) {
                frozenFolder.icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text(frozenFolder.localizedName)
                    .textStyle(textStyle)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                accessory
            }
        }
        .padding(.leading, UIPadding.menuDrawerSubFolder * CGFloat(level))
        .padding(canHaveChevron ? UIPadding.menuDrawerCellWithChevron : UIPadding.menuDrawerCell)
        .background(background)
    }

    @ViewBuilder
    private var accessory: some View {
        if cellType == .menuDrawer {
            if frozenFolder.role != .sent && frozenFolder.role != .trash {
                if !frozenFolder.formattedUnreadCount.isEmpty {
                    Text(frozenFolder.formattedUnreadCount)
                        .textStyle(.bodySmallMediumAccent)
                } else if frozenFolder.remoteUnreadCount > 0 {
                    UnreadIndicatorView()
                        .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionUnreadPastille)
                }
            }
        } else if isCurrentFolder {
            IKIcon(MailResourcesAsset.check)
        }
    }

    @ViewBuilder
    private var background: some View {
        if cellType == .menuDrawer {
            SelectionBackground(selectionType: isCurrentFolder ? .folder : .none, paddingLeading: 0, accentColor: accentColor)
        }
    }

    private func collapseFolder() {
        matomo.track(eventWithCategory: .menuDrawer, name: "collapseFolder", value: !frozenFolder.isExpanded)

        guard let liveFolder = frozenFolder.thaw() else { return }
        try? liveFolder.realm?.write {
            liveFolder.isExpanded = !frozenFolder.isExpanded
        }
    }
}

#Preview {
    FolderCell(folder: NestableFolder(content: PreviewHelper.sampleFolder, children: []), currentFolderId: nil)
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environmentObject(NavigationDrawerState())
}
