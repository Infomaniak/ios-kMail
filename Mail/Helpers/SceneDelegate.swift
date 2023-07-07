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

import CocoaLumberjackSwift
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, AccountManagerDelegate {
    var window: UIWindow?

    @LazyInjectService var cacheManager: CacheManageable
    @LazyInjectService var appLockHelper: AppLockHelper
    @LazyInjectService private var accountManager: AccountManager
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see
        // `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        accountManager.delegate = self
        updateWindowUI()
        setupLaunch()
        if let mailToURL = connectionOptions.urlContexts.first?.url {
            handleUrlOpen(mailToURL)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions`
        // instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        Task {
            await NotificationsHelper.updateUnreadCountBadge()
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        cacheManager.refreshCacheData()
        
        if UserDefaults.shared.isAppLockEnabled && appLockHelper.isAppLocked {
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
            appLockHelper.setTime()
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
        DispatchQueue.main.async { [weak self] in
            self?.showLoginView()
        }
    }

    private func setupLaunch() {
        if accountManager.accounts.isEmpty {
            showLoginView(animated: false)
        } else {
            showMainView(animated: false)
        }
    }

    func switchMailbox(_ mailbox: Mailbox) {
        accountManager.switchMailbox(newMailbox: mailbox)
        if let mailboxManager = accountManager.getMailboxManager(for: mailbox) {
            showMainView(mailboxManager: mailboxManager)
        }
    }

    func switchAccount(_ account: Account, mailbox: Mailbox? = nil) {
        accountManager.switchAccount(newAccount: account)
        cacheManager.refreshCacheData()

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

    func showMainView(mailboxManager: MailboxManager, animated: Bool = true) {
        setRootView(SplitView(mailboxManager: mailboxManager), animated: animated)
    }

    func showNoMailboxView(animated: Bool = true) {
        setRootView(NoMailboxView(), animated: animated)
    }

    func showMainView(animated: Bool = true) {
        if let mailboxManager = accountManager.currentMailboxManager {
            showMainView(mailboxManager: mailboxManager, animated: animated)
        } else if !accountManager.mailboxes.isEmpty && accountManager.mailboxes.allSatisfy({ !$0.isAvailable }) {
            setRootView(UnavailableMailboxesView(), animated: animated)
        } else {
            showNoMailboxView(animated: animated)
        }
    }

    func showLockView() {
        setRootView(LockedAppView(), animated: false)
    }

    func refreshCacheData() {
        guard let currentAccount = accountManager.currentAccount else {
            return
        }

        Task {
            do {
                let mailboxIdBeforeSwitching = accountManager.currentMailboxId
                try await accountManager.updateUser(for: currentAccount)
                accountManager.enableBugTrackerIfAvailable()

                try await accountManager.currentContactManager?.fetchContactsAndAddressBooks()

                if mailboxIdBeforeSwitching != accountManager.currentMailboxId {
                    showMainView()
                }
            } catch {
                DDLogError("Error while updating user account: \(error)")
            }
        }
    }

    // MARK: - Open URLs

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        _ = URLContexts.first { handleUrlOpen($0.url) }
    }

    @discardableResult
    func handleUrlOpen(_ url: URL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return false }

        if Constants.isMailTo(url) {
            NotificationCenter.default.post(
                name: .onOpenedMailTo,
                object: IdentifiableURLComponents(urlComponents: urlComponents)
            )
        }

        return true
    }
}
