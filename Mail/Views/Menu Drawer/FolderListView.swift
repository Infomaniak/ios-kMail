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

import InfomaniakBugTracker
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct NestableFolder: Identifiable {
    var id: String {
        content.id
    }

    let content: Folder
    let children: [NestableFolder]

    static func createFoldersHierarchy(from folders: [Folder]) -> [Self] {
        var parentFolders = [NestableFolder]()

        let sortedFolders = folders.sorted()
        for folder in sortedFolders {
            parentFolders.append(NestableFolder(
                content: folder,
                children: Self.createFoldersHierarchy(from: Array(folder.children))
            ))
        }

        return parentFolders
    }
}

class FolderListViewModel: ObservableObject {
    /// Special folders (eg. Inbox) for the current mailbox
    @Published var roleFolders = [NestableFolder]()
    /// User created folders for the current mailbox
    @Published var userFolders = [NestableFolder]()

    private var foldersObservationToken: NotificationToken?

    private let userFoldersSortDescriptors = [
        SortDescriptor(keyPath: \Folder.isFavorite, ascending: false),
        SortDescriptor(keyPath: \Folder.unreadCount, ascending: false),
        SortDescriptor(keyPath: \Folder.name)
    ]

    init(mailboxManager: MailboxManager) {
        // swiftlint:disable empty_count
        foldersObservationToken = mailboxManager.getRealm()
            .objects(Folder.self).where { $0.parents.count == 0 && $0.toolType == nil }
            .observe(on: DispatchQueue.main) { [weak self] results in
                switch results {
                case .initial(let folders):
                    self?.handleFoldersUpdate(folders)
                case .update(let folders, _, _, _):
                    withAnimation {
                        self?.handleFoldersUpdate(folders)
                    }
                case .error:
                    break
                }
            }
    }

    private func handleFoldersUpdate(_ folders: Results<Folder>) {
        roleFolders = NestableFolder.createFoldersHierarchy(from: Array(folders.where { $0.role != nil }))
        userFolders = NestableFolder.createFoldersHierarchy(from: Array(folders.where { $0.role == nil }))
    }
}

struct FolderListView: View {
    @StateObject private var viewModel: FolderListViewModel

    init(mailboxManager: MailboxManager) {
        _viewModel = StateObject(wrappedValue: FolderListViewModel(mailboxManager: mailboxManager))
    }

    var body: some View {
        RoleFoldersListView(folders: viewModel.roleFolders)

        IKDivider(hasVerticalPadding: true, horizontalPadding: UIConstants.menuDrawerHorizontalPadding)

        UserFoldersListView(folders: viewModel.userFolders)
    }
}
