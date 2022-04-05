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
import UIKit

struct FoldersListView: View {
    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 }) var folders

    var mailboxManager: MailboxManager
    weak var splitViewController: UISplitViewController?

    init(mailboxManager: MailboxManager, splitViewController: UISplitViewController?) {
        self.mailboxManager = mailboxManager
        _folders = .init(Folder.self, configuration: mailboxManager.realmConfiguration) { $0.parentLink.count == 0 }
        self.splitViewController = splitViewController
    }

    var body: some View {
        List(AnyRealmCollection(folders), children: \.listChildren) { folder in
            FolderCellView(
                mailboxManager: mailboxManager,
                folder: folder,
                icon: MailResourcesAsset.drawer,
                action: updateSplitView
            )
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
        if let splitVC = splitViewController, splitVC.isCollapsed {
            
        } else {
            let threadListVC = ThreadListViewController(mailboxManager: mailboxManager, folder: folder)
            splitViewController?.setViewController(threadListVC, for: .supplementary)
        }
    }
}
