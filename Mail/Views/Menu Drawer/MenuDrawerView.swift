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
import RealmSwift
import SwiftUI
import UIKit

struct MenuDrawerView: View {
    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 }) var folders
    private var mailboxManager: MailboxManager
    private weak var splitViewController: UISplitViewController?

    init(mailboxManager: MailboxManager, splitViewController: UISplitViewController) {
        self.mailboxManager = mailboxManager
        // swiftlint:disable empty_count
        _folders = .init(Folder.self, configuration: mailboxManager.realmConfiguration) { $0.parentLink.count == 0 }
        self.splitViewController = splitViewController
    }

    var body: some View {
        Text(mailboxManager.mailbox.mailbox)

        List(AnyRealmCollection(folders), children: \.listChildren) { folder in
            Button(folder.localizedName) {
                updateSplitView(with: folder)
            }
        }
        .listStyle(.plain)
        .onAppear {
            Task {
                await fetchFolders()
                MatomoUtils.track(view: ["MenuDrawer"])
            }
        }
    }

    private func updateSplitView(with folder: Folder) {
        let messageListVC = ThreadListViewController(mailboxManager: mailboxManager, folder: folder)
        splitViewController?.setViewController(messageListVC, for: .supplementary)
    }

    private func fetchFolders() async {
        do {
            try await mailboxManager.folders()
        } catch {
            print("Error while getting folders: \(error.localizedDescription)")
        }
    }
}
