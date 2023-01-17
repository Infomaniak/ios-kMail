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
import Realm
import SwiftUI

struct MoveMessageView: View {
    @ObservedObject private var viewModel: FolderListViewModel

    private let moveHandler: MoveSheet.MoveHandler

    init(mailboxManager: MailboxManager, moveHandler: @escaping MoveSheet.MoveHandler) {
        _viewModel = ObservedObject(wrappedValue: FolderListViewModel(mailboxManager: mailboxManager))
        self.moveHandler = moveHandler
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                RoleFoldersListView(folders: viewModel.roleFolders, isCompact: true)

                UserFoldersListView(folders: viewModel.userFolders, isCompact: true)
            }
        }
        .navigationTitle(MailResourcesStrings.Localizable.actionMove)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // TODO: Add folder
                } label: {
                    Image(resource: MailResourcesAsset.folderAdd)
                }
            }
        }
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
        MoveMessageView(mailboxManager:
            MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher())
        ) { _ in }
    }
}
