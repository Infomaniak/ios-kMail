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
import MailResources
import SwiftUI
import UIKit

class ThreadListViewController: MailCollectionViewController, FolderListViewDelegate {
    private var viewModel: ThreadListViewModel

    let isCompact: Bool

    init(mailboxManager: MailboxManager, folder: Folder?, isCompact: Bool) {
        viewModel = ThreadListViewModel(mailboxManager: mailboxManager, folder: folder)
        self.isCompact = isCompact
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        getThreads()

        collectionView.setCollectionViewLayout(Self.createLayout(), animated: true)
        collectionView.register(HostingCollectionViewCell<ThreadListCell>.self, forCellWithReuseIdentifier: "ThreadListCell")

        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.addTarget(self, action: #selector(getThreads), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isCompact {
            let menuButton = UIBarButtonItem(
                image: UIImage(systemName: "line.3.horizontal"),
                style: .plain,
                target: self,
                action: #selector(menuPressed)
            )
            parent?.navigationItem.leftBarButtonItem = menuButton
        }

        updateView()

        for indexPath in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MatomoUtils.track(view: ["ThreadList"])
    }

    func updateView() {
        parent?.navigationItem.title = viewModel.folder?.localizedName

        showEmptyView(viewModel.folder != nil)

        viewModel.onListUpdated = { [self] deletions, insertions, modifications, reload in
            guard !reload else {
                collectionView.reloadData()
                return
            }

            collectionView.deleteItems(at: deletions.map { IndexPath(item: $0, section: 0) })
            collectionView.insertItems(at: insertions.map { IndexPath(item: $0, section: 0) })
            collectionView.reloadItems(at: modifications.map { IndexPath(item: $0, section: 0) })
        }
    }

    @objc func getThreads(fromRefreshControl: Bool = false) {
        Task {
            await viewModel.fetchThreads()
            collectionView.reloadData()
            if collectionView.refreshControl?.isRefreshing == true {
                collectionView.refreshControl?.endRefreshing()
            }
        }
    }

    @objc func menuPressed() {
        let menuDrawerView = MenuDrawerView(mailboxManager: viewModel.mailboxManager, selectedFolderId: viewModel.folder?.id, isCompact: isCompact, delegate: self)
        let menuDrawerHostingController = UIHostingController(rootView: menuDrawerView)
        menuDrawerHostingController.view.backgroundColor = MailResourcesAsset.backgroundColor.color
        present(menuDrawerHostingController, animated: true)
    }

    private func showEmptyView(_ isHidden: Bool) {
        let emptyView = UIHostingController(rootView: EmptyThreadView(text: "dossier"))
        collectionView.backgroundView = isHidden ? nil : emptyView.view
    }

    private static func createLayout() -> UICollectionViewLayout {
        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        listConfiguration.showsSeparators = false

        listConfiguration.leadingSwipeActionsConfigurationProvider = { _ in
            let unreadAction = UIContextualAction(style: .normal, title: nil) { _, _, completion in
                // TODO: Mark the message as unread
                completion(true)
            }
            unreadAction.backgroundColor = MailResourcesAsset.unreadActionColor.color
            unreadAction.image = MailResourcesAsset.openLetter.image

            return UISwipeActionsConfiguration(actions: [unreadAction])
        }

        listConfiguration.trailingSwipeActionsConfigurationProvider = { _ in
            let menuAction = UIContextualAction(style: .normal, title: nil) { _, _, completion in
                // TODO: Display bottom sheet
                completion(true)
            }
            menuAction.backgroundColor = MailResourcesAsset.menuActionColor.color
            menuAction.image = MailResourcesAsset.threeDots.image

            let deleteAction = UIContextualAction(style: .destructive, title: nil) { _, _, completion in
                // TODO: Delete thread
                completion(true)
            }
            deleteAction.backgroundColor = MailResourcesAsset.destructiveActionColor.color
            deleteAction.image = MailResourcesAsset.bin.image

            return UISwipeActionsConfiguration(actions: [deleteAction, menuAction])
        }

        return UICollectionViewCompositionalLayout.list(using: listConfiguration)
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.threads.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThreadListCell", for: indexPath) as! HostingCollectionViewCell<ThreadListCell>
        let thread = viewModel.threads[indexPath.item]
        cell.host(ThreadListCell(mailboxManager: viewModel.mailboxManager, thread: thread), parent: self)
        return cell
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let threadView = ThreadView(mailboxManager: viewModel.mailboxManager, thread: viewModel.threads[indexPath.item])
        let threadHostingController = UIHostingController(rootView: threadView)
        if let splitVC = splitViewController, splitVC.isCollapsed {
            navigationController?.pushViewController(threadHostingController, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: threadHostingController)
            showDetailViewController(nav, sender: self)
        }
    }

    // MARK: - FolderListViewDelegate

    func didSelectFolder(_ folder: Folder) {
        viewModel.updateThreads(with: folder)
        collectionView.reloadData()
        updateView()
        getThreads()
    }
}
