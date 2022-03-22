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

class SplitViewController: UISplitViewController {
    var mailboxManager = AccountManager.instance.currentMailboxManager!

    // MARK: - Public methods

    convenience init() {
        self.init(style: .tripleColumn)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSplitViews()
    }

    // MARK: - Private

    private func setupSplitViews() {
        preferredSplitBehavior = .tile
        preferredDisplayMode = .twoBesideSecondary
        showsSecondaryOnlyButton = true

        let menuDrawerView = MenuDrawerView(
            mailboxManager: mailboxManager,
            splitViewController: self
        )
        .environment(\.realmConfiguration, mailboxManager.realmConfiguration)
        let menuDrawerHostingController = UIHostingController(rootView: menuDrawerView)
        setViewController(menuDrawerHostingController, for: .primary)

        let inboxFolder = AnyRealmCollection(mailboxManager.getRealm().objects(Folder.self).filter("role = 'INBOX'"))
        if let folder = inboxFolder.first {
            let threadListViewController = ThreadListViewController(mailboxManager: mailboxManager, folder: folder)
            let pepNav = UINavigationController(rootViewController: threadListViewController)
            setViewController(pepNav, for: .supplementary)
            setViewController(pepNav, for: .compact)
        }

        let threadView = ThreadView(mailboxManager: mailboxManager)
        let threadHostingController = UIHostingController(rootView: threadView)
        setViewController(threadHostingController, for: .secondary)
    }
}
