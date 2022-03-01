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

class MessageListViewController: MailCollectionViewController {
    private var viewModel: MessageListViewModel
    var selectedFolder: Folder?

    init(mailboxManager: MailboxManager) {
        viewModel = MessageListViewModel(mailboxManager: mailboxManager, folder: selectedFolder)
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.folder = selectedFolder
        title = selectedFolder?.localizedName
        getThreads()
    }

    func getThreads() {
        Task {
            await viewModel.fetchThreads()
            collectionView.reloadData()
        }
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.threads.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        let thread = viewModel.threads[indexPath.item]
        titleLabel?.text = thread.formattedSubject
        return cell
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedThread = dataTest[indexPath.item]
        let threadVC = ThreadViewController()
        threadVC.selectedThread = selectedFolder?.localizedName ?? "" + " - " + selectedThread
        showDetailViewController(threadVC, sender: self)
    }
}
