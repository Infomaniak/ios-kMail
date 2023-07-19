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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import Social
import SwiftUI
import UIKit

final class ShareNavigationViewController: UIViewController {
    /// Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = EarlyDIHook()

    @LazyInjectService private var accountManager: AccountManager

    private func overrideSnackBarPresenter(contextView: UIView) {
        let snackBarPresenter = Factory(type: SnackBarPresentable.self) { _, _ in
            SnackBarPresenter(contextView: contextView)
        }
        SimpleResolver.sharedResolver.store(factory: snackBarPresenter)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        overrideSnackBarPresenter(contextView: view)

        // Modify sheet size on iPadOS, property is ignored on iOS
        preferredContentSize = CGSize(width: 540, height: 620)

        // Make sure we are handling [NSExtensionItem]
        guard let extensionItems: [NSExtensionItem] = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem },
              !extensionItems.isEmpty else {
            dismiss(animated: true)
            return
        }

        let itemProviders: [NSItemProvider] = extensionItems.compactMap(\.attachments).flatMap { $0 }
        guard !itemProviders.isEmpty else {
            dismiss(animated: true)
            return
        }

        /// make sure we load the contact list asap.
        if let currentContactManager = accountManager.contactManager {
            Task {
                try await currentContactManager.fetchContactsAndAddressBooks()
            }
        }

        // We need to go threw wrapping to use SwiftUI in an NSExtension.
        let hostingController = UIHostingController(rootView: ComposeMessageWrapperView(dismissHandler: {
                self.dismiss(animated: true)
            },
            itemProviders: itemProviders))
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
