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

import InfomaniakCore
import MailCore
import MailResources
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, AccountManagerDelegate {
    var window: UIWindow?

    private var accountManager: AccountManager!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        accountManager = AccountManager.instance
        updateWindowUI()
        setupLaunch()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        if UserDefaults.shared.isAppLockEnabled && AppLockHelper.shared.isAppLocked {
            showLockView()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Cast rootViewController in a UIHostingViewController containing a LockedAppView and a UIWindow? environment variable
        if UserDefaults.shared.isAppLockEnabled && window?.rootViewController?.isKind(of: UIHostingController<ModifiedContent<
            LockedAppView,
            _EnvironmentKeyWritingModifier<UIWindow?>
        >>.self) != true {
            AppLockHelper.shared.setTime()
        }
    }

    func setRootViewController(_ viewController: UIViewController, animated: Bool = true) {
        guard let window = window else { return }
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        if animated {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }

    func setRootView<Content>(_ view: Content, animated: Bool = true) where Content: View {
        // Inject window in view as environment variable
        let view = view.environment(\.window, window)
        // Set root view controller
        let hostingController = UIHostingController(rootView: view)
        setRootViewController(hostingController)
    }

    func currentAccountNeedsAuthentication() {
        showLoginView()
    }

    private func setupLaunch() {
        if accountManager.accounts.isEmpty {
            showLoginView(animated: false)
        } else {
            showMainView(animated: false)
        }
        (UIApplication.shared.delegate as? AppDelegate)?.refreshCacheData()
    }

    func switchMailbox(_ mailbox: Mailbox) {
        AccountManager.instance.setCurrentMailboxForCurrentAccount(mailbox: mailbox)
        AccountManager.instance.saveAccounts()
        showMainView()
    }

    func switchAccount(_ account: Account, mailbox: Mailbox? = nil) {
        AccountManager.instance.switchAccount(newAccount: account)
        (UIApplication.shared.delegate as? AppDelegate)?.refreshCacheData()

        if let mailbox = mailbox {
            switchMailbox(mailbox)
        } else {
            showMainView()
        }
    }

    func updateWindowUI() {
        window?.tintColor = UserDefaults.shared.accentColor.primary.color
        window?.overrideUserInterfaceStyle = UserDefaults.shared.theme.interfaceStyle
    }

    // MARK: - Show views

    func showLoginView(animated: Bool = true) {
        setRootView(OnboardingView(), animated: animated)
    }

    func showMainView(animated: Bool = true) {
        setRootView(SplitView(), animated: animated)
    }

    func showLockView() {
        setRootView(LockedAppView(), animated: false)
    }

    // MARK: - Open URLs

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        _ = URLContexts.first { handleUrlOpen($0.url) }
    }

    private func handleUrlOpen(_ url: URL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let mailboxManager = accountManager.currentMailboxManager,
              let signatureResponse = mailboxManager.getSignatureResponse() else {
            return false
        }

        if urlComponents.scheme?.caseInsensitiveCompare("mailto") == .orderedSame {
            let draft = UnmanagedDraft(subject: urlComponents.getQueryItem(named: "subject") ?? "",
                                       body: urlComponents.getQueryItem(named: "body") ?? "",
                                       to: [Recipient(email: urlComponents.path, name: "")],
                                       cc: getRecipients(from: urlComponents, name: "cc"),
                                       bcc: getRecipients(from: urlComponents, name: "bcc"),
                                       identityId: "\(signatureResponse.defaultSignatureId)")

            let newMessageView = NewMessageView(isPresented: .constant(true), mailboxManager: mailboxManager, draft: draft)
            let viewController = UIHostingController(rootView: newMessageView)
            window?.rootViewController?.present(viewController, animated: true)
        }

        return true
    }

    private func getRecipients(from urlComponents: URLComponents, name: String) -> [Recipient] {
        return urlComponents.getQueryItem(named: name)?.split(separator: ",").map { Recipient(email: "\($0)", name: "") } ?? []
    }
}

extension URLComponents {
    func getQueryItem(named name: String) -> String? {
        return queryItems?.first { $0.name == name }?.value
    }
}
