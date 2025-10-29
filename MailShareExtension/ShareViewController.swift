/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import Social
import SwiftUI
import UIKit

final class ShareNavigationViewController: UIViewController {
    // periphery:ignore - Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = MailShareExtensionTargetAssembly()

    private func overrideSnackBarPresenter(contextView: UIView) {
        let snackBarPresenter = Factory(type: IKSnackBarPresentable.self) { _, _ in
            SnackBarPresenter(contextView: contextView)
        }
        SimpleResolver.sharedResolver.store(factory: snackBarPresenter)
    }

    private func overrideURLOpener() {
        let urlOpener = Factory(type: URLOpenable.self) { _, _ in
            URLOpener()
        }
        SimpleResolver.sharedResolver.store(factory: urlOpener)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        overrideSnackBarPresenter(contextView: view)
        overrideURLOpener()

        // Set theme
        overrideUserInterfaceStyle = UserDefaults.shared.theme.interfaceStyle
        view.tintColor = UserDefaults.shared.accentColor.primary.color

        // Modify sheet size on iPadOS, property is ignored on iOS
        preferredContentSize = CGSize(width: 540, height: 620)

        // Make sure we are handling [NSExtensionItem]
        guard let extensionItems: [NSExtensionItem] = extensionContext?.inputItems.compactMap({ $0 as? NSExtensionItem }),
              !extensionItems.isEmpty else {
            dismiss(animated: true)
            return
        }

        let itemProviders: [NSItemProvider] = extensionItems.filteredItemProviders
        guard !itemProviders.isEmpty else {
            dismiss(animated: true)
            return
        }

        /// Realm migration if needed
        ModelMigrator().migrateRealmIfNeeded()

        // We need to go threw wrapping to use SwiftUI in an NSExtension.
        let rootView = ComposeMessageWrapperView(itemProviders: itemProviders) {
            self.dismiss(animated: true)
        }
        .defaultAppStorage(.shared)

        let hostingController = UIHostingController(rootView: rootView)
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
