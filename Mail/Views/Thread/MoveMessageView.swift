//
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

import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct MoveMessageView: View {
    let moveHandler: MoveSheet.MoveHandler

    @ObservedResults(Folder.self) var folders

    private var nestableFolderSorted: [NestableFolder] {
        createNestedFoldersHierarchy(folders: Array(folders))
    }

    init(mailboxManager: MailboxManager, moveHandler: @escaping MoveSheet.MoveHandler) {
        self.moveHandler = moveHandler
        // swiftlint:disable empty_count
        _folders = ObservedResults(
            Folder.self,
            configuration: AccountManager.instance.currentMailboxManager?.realmConfiguration,
            where: { $0.role != .draft && $0.parentLink.count == 0 && $0.toolType == nil }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(nestableFolderSorted) { folder in
                    FolderCell(folder: folder)
                }
            }
        }
        .navigationTitle(MailResourcesStrings.Localizable.actionMove)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // TODO: Create a new folder
                } label: {
                    Image(resource: MailResourcesAsset.folderAdd)
                }
            }
        }
    }

    private func createNestedFoldersHierarchy(folders: [Folder]) -> [NestableFolder] {
        var parentFolders = [NestableFolder]()

        let sortedFolders = folders.sorted()
        for folder in sortedFolders {
            parentFolders.append(NestableFolder(content: folder, children: createNestedFoldersHierarchy(folders: Array(folder.children))))
        }

        return parentFolders
    }
}

extension MoveMessageView {
    static func sheetView(mailboxManager: MailboxManager, moveHandler: @escaping MoveSheet.MoveHandler) -> some View {
        SheetView {
            MoveMessageView(mailboxManager: mailboxManager, moveHandler: moveHandler)
        }
    }
}

struct MoveMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MoveMessageView(mailboxManager: PreviewHelper.sampleMailboxManager) { _ in }
    }
}
