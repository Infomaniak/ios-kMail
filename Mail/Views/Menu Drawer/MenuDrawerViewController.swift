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
import UIKit

class MenuDrawerViewController: MailCollectionViewController {
    private var viewModel = MenuDrawerViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = AccountManager.instance.currentMailboxManager?.mailbox.mailbox

        getFolders()
    }

    func getFolders() {
        Task {
            await viewModel.fetchFolders()
            collectionView.reloadData()
        }
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.folders.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        let folder = viewModel.folders[indexPath.item]
        titleLabel?.text = folder.localizedName
        return cell
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedFolder = viewModel.folders[indexPath.item].localizedName
        let messageLictVC = MessageListViewController()
        messageLictVC.selectedMailbox = selectedFolder
        splitViewController?.setViewController(messageLictVC, for: .supplementary)
    }
}
