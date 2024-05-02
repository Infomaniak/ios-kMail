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

import InfomaniakDI
import MailCore
import MailCoreUI
import RealmSwift
import SwiftUI

struct FolderListView: View {
    @StateObject private var viewModel: FolderListViewModel

    private let mailboxManager: MailboxManager

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
        _viewModel = StateObject(wrappedValue: FolderListViewModel(mailboxManager: mailboxManager))
    }

    var body: some View {
        Group {
            FoldersListView(folders: viewModel.roleFolders)
            IKDivider(type: .menu)
            UserFoldersListView(folders: viewModel.userFolders)
        }
        .onChange(of: mailboxManager) { newMailboxManager in
            viewModel.updateFolderListForMailboxManager(transactionable: newMailboxManager, animateInitialChanges: true)
        }
    }
}
