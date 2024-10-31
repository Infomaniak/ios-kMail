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
import SwiftUI

struct FoldersListView: View {
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var mailboxManager: MailboxManager

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
                    .contextMenu {
                        if isUserFoldersList {
                            Button {
                                Task {
                                    do {
                                        try await mailboxManager.modifyFolder(name: "RENAME", folder: folder.frozenContent)

                                    } catch {
                                        print("error")
                                    }
                                }
                            } label: {
                                Label("Modifier", image: MailResourcesAsset.pencilPlain.name)
                            }
                            Button {
                                Task {
                                    do {
                                        try await mailboxManager.deleteFolder(
                                            folder: folder.frozenContent
                                        )

                                    } catch {
                                        print("error")
                                    }
                                }
                            } label: {
                                Label("Supprimer", image: MailResourcesAsset.bin.name)
                            }
                        }
                    }
            }
        }
    }
}
