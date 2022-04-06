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

import Introspect
import MailCore
import MailResources
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
        preferredSplitBehavior = .displace
        preferredDisplayMode = .twoDisplaceSecondary
        showsSecondaryOnlyButton = true

        let menuDrawerView = MenuDrawerView(
            mailboxManager: mailboxManager,
            splitViewController: self
        )
        .environment(\.realmConfiguration, mailboxManager.realmConfiguration)
        let menuDrawerHostingController = UIHostingController(rootView: menuDrawerView)
        menuDrawerHostingController.view.backgroundColor = MailResourcesAsset.backgroundColor.color
        setViewController(menuDrawerHostingController, for: .primary)

        let inboxFolder = AnyRealmCollection(mailboxManager.getRealm().objects(Folder.self).filter("role = 'INBOX'"))
        if let folder = inboxFolder.first {
            let threadListViewController = ThreadListViewController(mailboxManager: mailboxManager, folder: folder)
            let threadListNav = UINavigationController(rootViewController: threadListViewController)
            setViewController(threadListNav, for: .supplementary)
            setViewController(threadListNav, for: .compact)
        }

        let emptyThreadView = EmptyThreadView()
        let threadHostingController = UIHostingController(rootView: emptyThreadView)
        setViewController(threadHostingController, for: .secondary)
    }
}

struct SplitView: View {
    var mailboxManager = AccountManager.instance.currentMailboxManager!
    var selectedFolder: Folder
    @State var navigationController: UINavigationController?

    init() {
        selectedFolder = mailboxManager.getRealm().objects(Folder.self).filter("role = 'INBOX'").first!
    }

    var body: some View {
        NavigationView {
            MenuDrawerView(mailboxManager: mailboxManager)

            ThreadList(mailboxManager: mailboxManager, folder: selectedFolder)

            EmptyThreadView()
        }
        .onRotate(perform: { orientation in
            guard let splitViewControler = navigationController?.splitViewController else { return }
            if orientation == .portrait || orientation == .portraitUpsideDown {
                splitViewControler.preferredSplitBehavior = .overlay
            } else if orientation == .landscapeLeft || orientation == .landscapeRight {
                splitViewControler.preferredSplitBehavior = .displace
            }
        })
        .introspectNavigationController { navController in
            navigationController = navController
            guard let splitViewControler = navController.splitViewController else { return }
            if UIDevice.current.orientation.isLandscape {
                splitViewControler.preferredSplitBehavior = .displace
            } else if UIDevice.current.orientation.isLandscape {
                splitViewControler.preferredSplitBehavior = .overlay
            }
            splitViewControler.preferredDisplayMode = .twoDisplaceSecondary
        }
    }
}

struct ThreadList: UIViewControllerRepresentable {
    var mailboxManager: MailboxManager
    var folder: Folder

    func makeUIViewController(context: Context) -> ThreadListViewController {
        return ThreadListViewController(mailboxManager: mailboxManager, folder: folder)
    }

    func updateUIViewController(_ uiViewController: ThreadListViewController, context: Context) {}
}


struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
