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

struct MoveEmailView: View {
    typealias MoveHandler = (Folder) -> Void

    @EnvironmentObject private var alert: GlobalAlert
    @EnvironmentObject private var mailboxManager: MailboxManager

    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.role != .draft && $0.parents.count == 0 && $0.toolType == nil }) var folders

    @LazyInjectService private var matomo: MatomoUtils

    let currentFolderId: String?
    let moveHandler: MoveEmailView.MoveHandler

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                listOfFolders(nestableFolders: NestableFolder
                    .createFoldersHierarchy(from: Array(folders.where { $0.role != nil })))
                IKDivider(horizontalPadding: 8)
                listOfFolders(nestableFolders: NestableFolder
                    .createFoldersHierarchy(from: Array(folders.where { $0.role == nil })))
            }
        }
        .navigationTitle(MailResourcesStrings.Localizable.actionMove)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    matomo.track(eventWithCategory: .createFolder, name: "fromMove")
                    alert.state = .createNewFolder(mode: .move(moveHandler: moveHandler))
                } label: {
                    MailResourcesAsset.folderAdd.swiftUIImage
                }
            }
        }
        .environment(\.folderCellType, .indicator)
        .matomoView(view: ["MoveEmailView"])
    }

    private func listOfFolders(nestableFolders: [NestableFolder]) -> some View {
        ForEach(nestableFolders) { nestableFolder in
            FolderCell(folder: nestableFolder, currentFolderId: currentFolderId) { folder in
                moveHandler(folder)
                NotificationCenter.default.post(Notification(name: Constants.dismissMoveSheetNotificationName))
            }
        }
    }
}

extension MoveEmailView {
    static func sheetView(mailboxManager: MailboxManager, from folderId: String?,
                          moveHandler: @escaping MoveEmailView.MoveHandler) -> some View {
        SheetView(mailboxManager: mailboxManager) {
            MoveEmailView(currentFolderId: folderId, moveHandler: moveHandler)
        }
    }
}

struct MoveMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MoveEmailView(currentFolderId: nil) { _ in /* Preview */ }
            .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
