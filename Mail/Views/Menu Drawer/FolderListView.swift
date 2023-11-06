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
    var id: Int {
        guard !content.isInvalidated else {
            return UUID().hashValue
        }

        // The id of a folder depends on its `remoteId` and the id of its children
        // Compute the id by doing an XOR with the id of each child
        return children.reduce(content.remoteId.hashValue) { $0 ^ $1.id }
    }

    let content: Folder
    let children: [NestableFolder]

    /// A view on `children` data, only valid Realm objects
    var displayableChildren: [NestableFolder] {
        children.filter { element in
            !element.content.isInvalidated
        }
    }

    static func createFoldersHierarchy(from folders: [Folder]) -> [Self] {
        var parentFolders = [NestableFolder]()

        for folder in folders {
            parentFolders.append(NestableFolder(
                content: folder,
                children: createFoldersHierarchy(from: Array(folder.children))
            ))
        }

        return parentFolders
    }
}

final class FolderListViewModel: ObservableObject {
    /// Special folders (eg. Inbox) for the current mailbox
    @Published var roleFolders = [NestableFolder]()
    /// User created folders for the current mailbox
    @Published var userFolders = [NestableFolder]()

    private var foldersObservationToken: NotificationToken?

    init(mailboxManager: MailboxManager) {
        updateFolderListForMailboxManager(mailboxManager, animateInitialChanges: false)
    }

    func updateFolderListForMailboxManager(_ mailboxManager: MailboxManager, animateInitialChanges: Bool) {
        foldersObservationToken = mailboxManager.getRealm()
            // swiftlint:disable:next empty_count
            .objects(Folder.self).where { $0.parents.count == 0 && $0.toolType == nil }
            .observe(on: DispatchQueue.main) { [weak self] results in
                switch results {
                case .initial(let folders):
                    withAnimation(animateInitialChanges ? .default : nil) {
                        self?.handleFoldersUpdate(folders)
                    }
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
        let sortedRoleFolders = folders.where { $0.role != nil }.sorted()
        roleFolders = NestableFolder.createFoldersHierarchy(from: Array(sortedRoleFolders))

        // sort Folders with case insensitive compare
        let sortedUserFolders = folders.where { $0.role == nil }.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        userFolders = NestableFolder.createFoldersHierarchy(from: Array(sortedUserFolders))
    }
}

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
            viewModel.updateFolderListForMailboxManager(newMailboxManager, animateInitialChanges: true)
        }
    }
}
