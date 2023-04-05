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

    @ObservedResults(Folder.self) var folders

    @LazyInjectService private var matomo: MatomoUtils

    let mailboxManager: MailboxManager
    let currentFolderId: String?
    let moveHandler: MoveEmailView.MoveHandler

    private var nestableFolderSorted = [NestableFolder]()

    init(mailboxManager: MailboxManager, from currentFolderId: String?, moveHandler: @escaping MoveEmailView.MoveHandler) {
        self.mailboxManager = mailboxManager
        self.currentFolderId = currentFolderId
        self.moveHandler = moveHandler

        // swiftlint:disable empty_count
        _folders = ObservedResults(
            Folder.self,
            configuration: AccountManager.instance.currentMailboxManager?.realmConfiguration
        ) { $0.role != .draft && $0.parents.count == 0 && $0.toolType == nil }
        nestableFolderSorted = NestableFolder.createFoldersHierarchy(from: Array(folders))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                listOfFolders(nestableFolders: nestableFolderSorted.filter { $0.content.role != nil })
                IKDivider(horizontalPadding: 8)
                listOfFolders(nestableFolders: nestableFolderSorted.filter { $0.content.role == nil })
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
    static func sheetView(mailboxManager: MailboxManager, from folderId: String?, moveHandler: @escaping MoveEmailView.MoveHandler) -> some View {
        SheetView(mailboxManager: mailboxManager) {
            MoveEmailView(mailboxManager: mailboxManager, from: folderId, moveHandler: moveHandler)
        }
    }
}

struct MoveMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MoveEmailView(mailboxManager: PreviewHelper.sampleMailboxManager, from: nil) { _ in /* Preview */ }
    }
}
