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
import InfomaniakCoreSwiftUI
import MailCore
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI

struct FoldersListView: View {
    @EnvironmentObject private var mainViewState: MainViewState

    let folders: [NestableFolder]

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(folders) { folder in
                FolderCell(folder: folder,
                           currentFolderId: mainViewState.selectedFolder.remoteId,
                           matomoCategory: .menuDrawer)
                    .background(RoundedRectangle(cornerRadius: IKRadius.medium)
                        .fill(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor))
            }
        }
    }
}
