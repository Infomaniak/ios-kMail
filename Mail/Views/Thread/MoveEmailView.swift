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

struct MoveAction: Identifiable {
    var id: String {
        return "\(target.id)\(fromFolderId ?? "")"
    }

    let fromFolderId: String?
    let target: ActionsTarget
}

struct MoveEmailView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager

    typealias MoveHandler = (Folder) -> Void

    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.role != .draft && $0.parents.count == 0 && $0.toolType == nil }) var folders
    @State private var isShowingCreateFolderAlert = false

    let moveAction: MoveAction

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
                    isShowingCreateFolderAlert.toggle()
                } label: {
                    MailResourcesAsset.folderAdd.swiftUIImage
                }
            }
        }
        .environment(\.folderCellType, .indicator)
        .matomoView(view: ["MoveEmailView"])
        .customAlert(isPresented: $isShowingCreateFolderAlert) {
            CreateFolderView(mode: .move { newFolder in
                Task {
                    try await move(to: newFolder)
                }
            })
        }
    }

    private func move(to folder: Folder) async throws {
        let undoRedoAction: UndoRedoAction
        let snackBarMessage: String
        switch moveAction.target {
        case .threads(let threads, _):
            guard threads.first?.folder != folder else { return }
            undoRedoAction = try await mailboxManager.move(threads: threads, to: folder)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadsMoved(folder.localizedName)
        case .message(let message):
            guard message.folderId != folder.id else { return }
            var messages = [message]
            messages.append(contentsOf: message.duplicates)
            undoRedoAction = try await mailboxManager.move(messages: messages, to: folder)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarMessageMoved(folder.localizedName)
        }

        IKSnackBar.showCancelableSnackBar(message: snackBarMessage,
                                          cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                          undoRedoAction: undoRedoAction,
                                          mailboxManager: mailboxManager)
    }

    private func listOfFolders(nestableFolders: [NestableFolder]) -> some View {
        ForEach(nestableFolders) { nestableFolder in
            FolderCell(folder: nestableFolder, currentFolderId: moveAction.fromFolderId) { folder in
                Task {
                    try await move(to: folder)
                }
                NotificationCenter.default.post(Notification(name: Constants.dismissMoveSheetNotificationName))
            }
        }
    }
}

extension MoveEmailView {
    static func sheetView(moveAction: MoveAction) -> some View {
        SheetView {
            MoveEmailView(moveAction: moveAction)
        }
    }
}

struct MoveMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MoveEmailView(moveAction: MoveAction(fromFolderId: PreviewHelper.sampleFolder.id,
                                             target: .message(PreviewHelper.sampleMessage)))
            .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
