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
import SwiftUI

class ThreadListViewController: MailCollectionViewController {
    private var viewModel: ThreadListViewModel

    init(mailboxManager: MailboxManager, folder: Folder) {
        viewModel = ThreadListViewModel(mailboxManager: mailboxManager, folder: folder)
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.folder.localizedName
        viewModel.onListUpdated = { [self] deletions, insertions, modifications, reload in
            guard !reload else {
                collectionView.reloadData()
                return
            }

            collectionView.deleteItems(at: deletions.map { IndexPath(item: $0, section: 0) })
            collectionView.insertItems(at: insertions.map { IndexPath(item: $0, section: 0) })
            collectionView.reloadItems(at: modifications.map { IndexPath(item: $0, section: 0) })
        }
        getThreads()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MatomoUtils.track(view: ["ThreadList"])
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
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! UICollectionViewListCell
        let thread = viewModel.threads[indexPath.item]
        var content = cell.defaultContentConfiguration()
        content.text = thread.formattedSubject
        cell.contentConfiguration = content
        return cell
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let threadView = ThreadView(mailboxManager: viewModel.mailboxManager, thread: viewModel.threads[indexPath.item])
        let threadHostingController = UIHostingController(rootView: threadView)
        showDetailViewController(threadHostingController, sender: self)
    }
}
