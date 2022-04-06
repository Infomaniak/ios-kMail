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
import UIKit
import SwiftUI

struct FoldersListView: View {
    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 && $0.role == nil }) var folders

    @State private var unfoldFolders = false

    var mailboxManager: MailboxManager
    weak var splitViewController: UISplitViewController?

    init(mailboxManager: MailboxManager, splitViewController: UISplitViewController?) {
        self.mailboxManager = mailboxManager
        _folders = .init(Folder.self, configuration: mailboxManager.realmConfiguration) { $0.parentLink.count == 0 && $0.role == nil }
        self.splitViewController = splitViewController
    }

    var body: some View {
        DisclosureGroup(isExpanded: $unfoldFolders) {
            ForEach(AnyRealmCollection(folders.sorted(by: [SortDescriptor(keyPath: \Folder.isFavorite, ascending: false)]))) { folder in
                FolderCellView(folder: folder, icon: MailResourcesAsset.drawer, action: updateSplitView)
            }
            .accentColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
        } label: {
            Text("Dossiers")
                .padding(.trailing, 5)

            Button(action: addNewFolder) {
                Image(uiImage: MailResourcesAsset.addFolder.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16)
            }
        }
        .accentColor(Color(MailResourcesAsset.primaryTextColor.color))
        .padding([.top, .bottom], 9)
        .onAppear {
            Task {
                await fetchFolders()
                MatomoUtils.track(view: ["MenuDrawer"])
            }
            print(MailboxManager.constants.rootDocumentsURL)
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
        let messageListVC = ThreadListViewController(mailboxManager: mailboxManager, folder: folder)
        splitViewController?.setViewController(messageListVC, for: .supplementary)
    }

    private func addNewFolder() {
        // add new folder
    }
}
