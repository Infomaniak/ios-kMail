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
import RealmSwift
import SwiftUI
import UIKit

struct UserFoldersListView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var splitViewManager: SplitViewManager

    @State private var isExpanded = true
    @State private var isShowingCreateFolderAlert = false

    private let folders: [NestableFolder]
    private let hasSubFolders: Bool

    init(folders: [NestableFolder]) {
        self.folders = folders
        hasSubFolders = folders.contains { !$0.children.isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: UIPadding.menuDrawerCellChevronSpacing) {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                        matomo.track(eventWithCategory: .menuDrawer, name: "customFolders", value: isExpanded)
                    }
                } label: {
                    HStack(spacing: UIPadding.menuDrawerCellChevronSpacing) {
                        ChevronIcon(style: isExpanded ? .up : .down)
                        Text(MailResourcesStrings.Localizable.buttonFolders)
                            .textStyle(.bodySmallSecondary)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonExpandCustomFolders)

                Button {
                    matomo.track(eventWithCategory: .createFolder, name: "fromMenuDrawer")
                    isShowingCreateFolderAlert.toggle()
                } label: {
                    MailResourcesAsset.addCircle.swiftUIImage
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .accessibilityLabel(MailResourcesStrings.Localizable.newFolderDialogTitle)
                .customAlert(isPresented: $isShowingCreateFolderAlert) {
                    CreateFolderView(mode: .create)
                }
            }
            .padding(value: .regular)

            if isExpanded {
                if folders.isEmpty {
                    Text(MailResourcesStrings.Localizable.noFolderTitle)
                        .textStyle(.bodySmallSecondary)
                        .padding(value: .regular)
                } else {
                    LazyVStack {
                        ForEach(folders) { folder in
                            FolderCell(folder: folder,
                                       currentFolderId: splitViewManager.selectedFolder?.id,
                                       canCollapseSubFolders: hasSubFolders,
                                       matomoCategory: .menuDrawer)
                        }
                    }
                }
            }
        }
    }
}
