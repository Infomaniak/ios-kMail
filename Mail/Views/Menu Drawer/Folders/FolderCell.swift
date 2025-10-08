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
import MailResources
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
                            isCurrentFolder: isCurrentFolder,
                            canCollapseSubFolders: canCollapseSubFolders
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
                            canCollapseSubFolders: canCollapseSubFolders,
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

struct FolderCellContent: View {
    @LazyInjectService var matomo: MatomoUtils

    private static let maximumSubFolderLevel = 2

    @Environment(\.folderCellType) private var cellType
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var mainViewState: MainViewState

    @State private var currentFolder: Folder?

    @ModalState private var destructiveAlert: DestructiveActionAlertState?

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

    private var shouldHaveChevron: Bool

    init(frozenFolder: Folder, level: Int, isCurrentFolder: Bool, canCollapseSubFolders: Bool = false) {
        assert(frozenFolder.isFrozen, "expecting frozenFolder to be frozen")
        self.frozenFolder = frozenFolder
        self.level = min(level, Self.maximumSubFolderLevel)
        self.isCurrentFolder = isCurrentFolder
        self.canCollapseSubFolders = canCollapseSubFolders
        shouldHaveChevron = frozenFolder.hasSubFolders && level == 0
    }

    var body: some View {
        HStack(spacing: 0) {
            if canHaveChevron {
                Button(action: collapseFolder) {
                    ChevronIcon(direction: frozenFolder.isExpanded ? .up : .down)
                        .padding(value: .medium)
                }
                .accessibilityLabel(MailResourcesStrings.Localizable
                    .contentDescriptionButtonExpandFolder(frozenFolder.name))
                .opacity(shouldHaveChevron ? 1 : 0)
            }

            HStack(spacing: IKPadding.menuDrawerCellSpacing) {
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
        .padding(.leading, IKPadding.menuDrawerSubFolder * CGFloat(level))
        .padding(canHaveChevron ? IKPadding.menuDrawerCellWithChevron : IKPadding.menuDrawerCell)
        .background(FolderCellBackground(isCurrentFolder: isCurrentFolder))
        .dropThreadDestination(destinationFolder: frozenFolder, enabled: frozenFolder.isAcceptingMove)
        .contextMenu {
            if frozenFolder.role == nil && cellType != .move {
                Button {
                    matomo.track(eventWithCategory: .manageFolder, name: "rename")
                    currentFolder = frozenFolder
                } label: {
                    Label {
                        Text(MailResourcesStrings.Localizable.actionRename)
                    } icon: {
                        MailResourcesAsset.pencilPlain.swiftUIImage
                    }
                }
                Button {
                    matomo.track(eventWithCategory: .manageFolder, name: "delete")

                    destructiveAlert = DestructiveActionAlertState(type: .deleteFolder(frozenFolder)) {
                        matomo.track(eventWithCategory: .manageFolder, name: "deleteConfirm")
                        await tryOrDisplayError {
                            try await mailboxManager.deleteFolder(
                                folder: frozenFolder
                            )
                            if mainViewState.selectedFolder.remoteId == frozenFolder.remoteId,
                               let inbox = mailboxManager.getFolder(with: .inbox)?.freezeIfNeeded() {
                                mainViewState.selectedFolder = inbox
                            }
                        }
                    }
                } label: {
                    Label {
                        Text(MailResourcesStrings.Localizable.actionDelete)
                    } icon: {
                        MailResourcesAsset.bin.swiftUIImage
                    }
                }
            }
        }
        .mailCustomAlert(item: $currentFolder) { folder in
            CreateFolderView(mode: .modify(modifiedFolder: folder))
        }
        .mailCustomAlert(item: $destructiveAlert) { item in
            DestructiveActionAlertView(destructiveAlert: item)
        }
    }

    @ViewBuilder
    private var accessory: some View {
        if cellType == .menuDrawer {
            switch frozenFolder.countToDisplay {
            case .count(let count):
                Text(count, format: .indicatorCappedCount)
                    .textStyle(.bodySmallMediumAccent)
            case .indicator:
                UnreadIndicatorView()
                    .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionUnreadPastille)
            case .none:
                EmptyView()
            }
        } else if isCurrentFolder {
            MailResourcesAsset.check
                .iconSize(.medium)
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

struct FolderCellBackground: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor
    @Environment(\.isHovered) private var isHovered
    @Environment(\.folderCellType) private var cellType

    let isCurrentFolder: Bool

    var body: some View {
        if cellType == .menuDrawer {
            SelectionBackground(
                selectionType: (isCurrentFolder || isHovered) ? .folder : .none,
                paddingLeading: 0,
                accentColor: accentColor
            )
            .background(RoundedRectangle(cornerRadius: IKRadius.medium)
                .fill(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor))
        }
    }
}

#Preview {
    FolderCell(folder: NestableFolder(content: PreviewHelper.sampleFolder, children: []), currentFolderId: nil)
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environmentObject(NavigationDrawerState())
}
