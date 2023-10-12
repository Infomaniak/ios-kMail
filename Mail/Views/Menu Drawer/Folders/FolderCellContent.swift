/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

struct FolderCellContent: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @EnvironmentObject private var mailboxManager: MailboxManager

    @Environment(\.folderCellType) var cellType

    private let folderPrimaryKey: String
    private let name: String
    private let localizedName: String
    private let isExpanded: Bool
    private let isChildrenEmpty: Bool
    private let formattedUnreadCount: String
    private let remoteUnreadCount: Int
    private let icon: Image
    private let role: FolderRole?
    private let level: Int
    private let isCurrentFolder: Bool
    private let canCollapseSubFolders: Bool

    init(folderPrimaryKey: String,
         name: String,
         localizedName: String,
         isExpanded: Bool,
         isChildrenEmpty: Bool,
         formattedUnreadCount: String,
         remoteUnreadCount: Int,
         icon: Image,
         role: FolderRole?,
         level: Int, isCurrentFolder: Bool, canCollapseSubFolders: Bool = false) {
        self.folderPrimaryKey = folderPrimaryKey
        self.name = name
        self.localizedName = localizedName
        self.isExpanded = isExpanded
        self.isChildrenEmpty = isChildrenEmpty
        self.formattedUnreadCount = formattedUnreadCount
        self.remoteUnreadCount = remoteUnreadCount
        self.icon = icon
        self.role = role

        self.level = min(level, UIConstants.menuDrawerMaximumSubFolderLevel)
        self.isCurrentFolder = isCurrentFolder
        self.canCollapseSubFolders = canCollapseSubFolders
    }

    private var textStyle: MailTextStyle {
        if cellType == .menuDrawer {
            return isCurrentFolder ? .bodyMediumAccent : .bodyMedium
        }
        return .body
    }

    var body: some View {
        HStack(spacing: UIPadding.menuDrawerCellChevronSpacing) {
            if canCollapseSubFolders && cellType == .menuDrawer {
                Button(action: collapseFolder) {
                    ChevronIcon(style: isExpanded ? .up : .down)
                }
                .opacity(level == 0 && !isChildrenEmpty ? 1 : 0)
                .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonExpandFolder(name))
            }

            HStack(spacing: UIPadding.menuDrawerCellSpacing) {
                icon.resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.accentColor)

                Text(localizedName)
                    .textStyle(textStyle)
                    .lineLimit(1)

                Spacer(minLength: UIPadding.regular)

                accessory
            }
        }
        .padding(.leading, UIPadding.menuDrawerSubFolder * CGFloat(level))
        .padding(UIPadding.menuDrawerCell)
        .background(background)
    }

    @ViewBuilder
    private var accessory: some View {
        if cellType == .menuDrawer {
            if role != .sent && role != .trash {
                if !formattedUnreadCount.isEmpty {
                    Text(formattedUnreadCount)
                        .textStyle(.bodySmallMediumAccent)
                } else if remoteUnreadCount > 0 {
                    UnreadIndicatorView()
                        .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionUnreadPastille)
                }
            }
        } else if isCurrentFolder {
            MailResourcesAsset.check.swiftUIImage
                .resizable()
                .frame(width: 16, height: 16)
        }
    }

    @ViewBuilder
    private var background: some View {
        if cellType == .menuDrawer {
            SelectionBackground(selectionType: isCurrentFolder ? .folder : .none, paddingLeading: 0, accentColor: accentColor)
        }
    }

    private func collapseFolder() {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .menuDrawer, name: "collapseFolder", value: !isExpanded)

        let realm = mailboxManager.getRealm()
        let folder = realm.object(ofType: Folder.self, forPrimaryKey: folderPrimaryKey)
        guard let liveFolder = folder?.thaw() else { return }

        try? liveFolder.realm?.write {
            liveFolder.isExpanded = !liveFolder.isExpanded
        }
    }
}
