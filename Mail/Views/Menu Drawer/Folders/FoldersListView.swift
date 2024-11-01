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
import MailCore
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI

struct FoldersListView: View {
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ModalState private var isShowingCreateFolderAlert = false
    @State private var currentFolder: Folder?

    private let folders: [NestableFolder]
    private let hasSubFolders: Bool
    private let isUserFoldersList: Bool

    init(folders: [NestableFolder], isUserFoldersList: Bool) {
        self.folders = folders
        self.isUserFoldersList = isUserFoldersList
        hasSubFolders = folders.contains { !$0.children.isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(folders) { folder in

                FolderCell(folder: folder,
                           currentFolderId: mainViewState.selectedFolder.remoteId,
                           canCollapseSubFolders: hasSubFolders,
                           matomoCategory: .menuDrawer)
                    .background(RoundedRectangle(cornerRadius: 10).fill(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor))
                    .contextMenu {
                        if isUserFoldersList {
                            Button {
                                currentFolder = folder.frozenContent
                                isShowingCreateFolderAlert.toggle()
                            } label: {
                                Label {
                                    Text(MailResourcesStrings.Localizable.actionRename)
                                } icon: {
                                    MailResourcesAsset.pencilPlain.swiftUIImage
                                }
                            }
                            Button {
                                Task {
                                    do {
                                        try await mailboxManager.deleteFolder(
                                            folder: folder.frozenContent
                                        )

                                    } catch {
                                        print(error)
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
                    .customAlert(isPresented: $isShowingCreateFolderAlert) {
                        CreateFolderView(mode: .modify, folder: currentFolder)
                    }
            }
        }
    }
}
