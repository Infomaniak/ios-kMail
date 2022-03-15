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
import SwiftUI
import UIKit

struct MenuDrawerView: View {
    @ObservedObject private var viewModel: MenuDrawerViewModel
    private weak var splitViewController: UISplitViewController?

    init(viewModel: MenuDrawerViewModel, splitViewController: UISplitViewController) {
        self.viewModel = viewModel
        self.splitViewController = splitViewController
    }

    var body: some View {
        Text(viewModel.mailboxManager.mailbox.mailbox)

        List(viewModel.folders, children: \.listChildren) { folder in
            Button(folder.localizedName) {
                updateSplitView(with: folder)
            }
        }.listStyle(.plain)
            .onAppear {
                Task {
                    await viewModel.fetchFolders()
                }
            }
    }

    private func updateSplitView(with folder: Folder) {
        let messageListVC = ThreadListViewController(mailboxManager: viewModel.mailboxManager, folder: folder)
        splitViewController?.setViewController(messageListVC, for: .supplementary)
    }
}
