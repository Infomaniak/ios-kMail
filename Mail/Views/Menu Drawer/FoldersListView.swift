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
import MailCore
import MailResources
import RealmSwift
import SwiftUI

protocol FolderListViewDelegate: AnyObject {
    func didSelectFolder(_ folder: Folder)
}

struct FoldersListView: View {
    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 }) var folders
    @Environment(\.presentationMode) var presentationMode

    var mailboxManager: MailboxManager
    weak var splitViewController: UISplitViewController?
    var isCompact: Bool

    weak var delegate: FolderListViewDelegate?

    init(
        mailboxManager: MailboxManager,
        splitViewController: UISplitViewController?,
        isCompact: Bool,
        delegate: FolderListViewDelegate?
    ) {
        self.mailboxManager = mailboxManager
        _folders = .init(Folder.self, configuration: mailboxManager.realmConfiguration) { $0.parentLink.count == 0 }
        self.splitViewController = splitViewController
        self.isCompact = isCompact
        self.delegate = delegate
    }

    var body: some View {
        List(AnyRealmCollection(folders), children: \.listChildren) { folder in

            if isCompact {
                Button {
                    updateSplitView(with: folder)
                } label: {
                    FolderCellView(
                        folder: folder,
                        icon: MailResourcesAsset.drawer
                    )
                }
            } else {
                NavigationLink(destination: ThreadList(mailboxManager: mailboxManager, folder: folder, isCompact: isCompact)) {
                    FolderCellView(
                        folder: folder,
                        icon: MailResourcesAsset.drawer
                    )
                }
            }
        }
        .listStyle(.plain)
        .accentColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
        .onAppear {
            Task {
                await fetchFolders()
                MatomoUtils.track(view: ["MenuDrawer"])
            }
        }
    }

    // MARK: - Private functions

    private func fetchFolders() async {
        do {
            try await mailboxManager.folders()
        } catch {
            print("Error while getting folders: \(error.localizedDescription)")
        }
    }

    private func updateSplitView(with folder: Folder) {
        delegate?.didSelectFolder(folder)
        presentationMode.wrappedValue.dismiss()
    }
}
