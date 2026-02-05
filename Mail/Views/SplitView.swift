/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import Combine
import InAppTwoFactorAuthentication
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import KSuite
import MailCore
import MailCoreUI
import MailResources
import MyKSuite
import NavigationBackport
import OSLog
import RealmSwift
import SwiftModalPresentation
import SwiftUI
import VersionChecker
@_spi(Advanced) import SwiftUIIntrospect

public class SplitViewManager: ObservableObject {
    @InjectService private var platformDetector: PlatformDetectable

    var splitViewController: UISplitViewController?

    func adaptToProminentThreadView() {
        guard !platformDetector.isMac else {
            return
        }

        splitViewController?.hide(.primary)
        if splitViewController?.splitBehavior == .overlay {
            splitViewController?.hide(.supplementary)
        }
    }
}

struct SplitView: View {
    @InjectService private var platformDetector: PlatformDetectable
    @LazyInjectService private var orientationManager: OrientationManageable
    @LazyInjectService private var appLaunchCounter: AppLaunchCounter
    @LazyInjectService private var cacheManager: CacheManageable
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var reviewManager: ReviewManageable

    @Environment(\.openURL) private var openURL
    @Environment(\.currentUser) private var currentUser
    @Environment(\.isCompactWindow) private var isCompactWindow

    @EnvironmentObject private var mainViewState: MainViewState

    @Weak private var splitViewController: UISplitViewController?

    @StateObject private var navigationDrawerState = NavigationDrawerState()
    @StateObject private var splitViewManager = SplitViewManager()
    @StateObject private var quickActionsManager = QuickActionsManager.instance

    let mailboxManager: MailboxManager

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                if isCompactWindow {
                    ZStack {
                        NavigationStack(path: $mainViewState.threadPath) {
                            ThreadListManagerView()
                                .accessibilityHidden(navigationDrawerState.isOpen)
                                .navigationDestination(for: Thread.self) { thread in
                                    ThreadView(thread: thread)
                                }
                        }

                        NavigationDrawer()
                    }
                } else {
                    NavigationSplitView {
                        MenuDrawerView()
                            .navigationBarHidden(!navigationDrawerState.useNativeToolbar || isCompactWindow)
                    } content: {
                        ThreadListManagerView()
                    } detail: {
                        if let thread = mainViewState.selectedThread {
                            ThreadView(thread: thread)
                        } else {
                            EmptyStateView.emptyThread(from: mainViewState.selectedFolder)
                        }
                    }
                }
            } else {
                if isCompactWindow {
                    ZStack {
                        NBNavigationStack(path: $mainViewState.threadPath) {
                            ThreadListManagerView()
                                .accessibilityHidden(navigationDrawerState.isOpen)
                                .nbNavigationDestination(for: Thread.self) { thread in
                                    ThreadView(thread: thread)
                                }
                        }
                        .nbUseNavigationStack(.whenAvailable)
                        .navigationViewStyle(.stack)

                        NavigationDrawer()
                    }
                } else {
                    NavigationView {
                        MenuDrawerView()
                            .navigationBarHidden(!navigationDrawerState.useNativeToolbar || isCompactWindow)

                        ThreadListManagerView()

                        if let thread = mainViewState.selectedThread {
                            ThreadView(thread: thread)
                        } else {
                            EmptyStateView.emptyThread(from: mainViewState.selectedFolder)
                        }
                    }
                }
            }
        }
        .easterEggOverlay($mainViewState.easterEgg)
        .mailDiscoveryPresenter(isPresented: $mainViewState.isShowingUpdateAvailable) {
            UpdateVersionView(image: MailResourcesAsset.documentStarsRocket.swiftUIImage) { willUpdate in
                if willUpdate {
                    openURL(URLConstants.getStoreURL().url)
                    matomo.track(eventWithCategory: .appUpdate, name: "discoverNow")
                } else {
                    matomo.track(eventWithCategory: .appUpdate, name: "discoverLater")
                }
            }
        }
        .mailDiscoveryPresenter(isPresented: $mainViewState.isShowingSyncDiscovery) {
            DiscoveryView(item: .syncDiscovery) {
                guard UserDefaults.shared.showSyncCounter < 3 else {
                    UserDefaults.shared.shouldPresentSyncDiscovery = false
                    return
                }
                UserDefaults.shared.nextShowSync = appLaunchCounter.value + Constants.nextOpeningBeforeSync
            } completionHandler: { willSync in
                guard willSync else { return }
                if willSync {
                    matomo.track(eventWithCategory: .syncAutoConfig, name: "discoverNow")
                } else {
                    matomo.track(eventWithCategory: .syncAutoConfig, name: "discoverLater")
                }
                mainViewState.isShowingSyncProfile = true
            }
        }
        .mailDiscoveryPresenter(isPresented: $mainViewState.isShowingSetAppAsDefaultDiscovery) {
            DiscoveryView(item: .setAsDefaultAppDiscovery) {
                UserDefaults.shared.shouldPresentSetAsDefaultDiscovery = false
            } completionHandler: { willSetAsDefault in
                guard willSetAsDefault, let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                if willSetAsDefault {
                    matomo.track(eventWithCategory: .setAsDefaultApp, name: "discoverNow")
                } else {
                    matomo.track(eventWithCategory: .setAsDefaultApp, name: "discoverLater")
                }
                openURL(settingsUrl)
            }
        }
        .mailMyKSuiteFloatingPanel(isPresented: $mainViewState.isShowingMyKSuiteUpgrade, configuration: .mail)
        .kSuitePanel(
            isPresented: $mainViewState.isShowingKSuiteProUpgrade,
            backgroundColor: MailResourcesAsset.backgroundSecondaryColor.swiftUIColor,
            configuration: .standard, // Always standard on Mail
            isAdmin: mailboxManager.mailbox.ownerOrAdmin,
        )
        .mailPremiumPanel(isPresented: $mainViewState.isShowingMailPremiumUpgrade)
        .fullScreenCover(isPresented: $mainViewState.isShowingSyncProfile) {
            SyncProfileNavigationView()
        }
        .sheet(item: $mainViewState.settingsViewConfig,
               desktopIdentifier: DesktopWindowIdentifier.settingsWindowIdentifier) { config in
            SettingsNavigationView(baseNavigationPath: config.baseNavigationPath)
                // Needed for macOS 12 else environment isn't correctly passed
                .environment(\.currentUser, MandatoryEnvironmentContainer(value: currentUser.value))
        }
        .sheet(item: $mainViewState.composeMessageIntent,
               desktopIdentifier: DesktopWindowIdentifier.composeWindowIdentifier) { intent in
            ComposeMessageIntentView(composeMessageIntent: intent)
        }
        .sheet(item: $mainViewState.isShowingSafariView) { safariContent in
            SafariWebView(url: safariContent.url)
                .ignoresSafeArea()
        }
        .task(id: currentUser.value.id) {
            await cacheManager.refreshCacheDataFor(userId: currentUser.value.id)
        }
        .sceneLifecycle(willEnterForeground: willEnterForeground)
        .onOpenURL { url in
            handleOpenUrl(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .closeDrawer).receive(on: DispatchQueue.main),
                   perform: handleCloseDrawer)
        .onReceive(NotificationCenter.default.publisher(for: .openNotificationSettings).receive(on: DispatchQueue.main),
                   perform: handleOpenNotificationSettings)
        .onReceive(NotificationCenter.default.publisher(for: .userPerformedHomeScreenShortcut).receive(on: DispatchQueue.main),
                   perform: handleApplicationShortcut)
        .onAppear {
            orientationManager.setOrientationLock(.all)
            handleShortcutItem()
        }
        .task(id: mailboxManager.mailbox.objectId) {
            await fetchSignatures()
        }
        .task(id: mailboxManager.mailbox.objectId) {
            await fetchFolders()
        }
        .onRotate { orientation in
            guard let interfaceOrientation = orientation else { return }
            setupBehaviour(orientation: interfaceOrientation)
        }
        .introspect(.navigationView(style: .columns), on: .iOS(.v15, .v16, .v17, .v18, .v26)) { splitViewController in
            guard let interfaceOrientation = splitViewController.view.window?.windowScene?.interfaceOrientation else { return }
            guard self.splitViewController != splitViewController else { return }
            self.splitViewController = splitViewController
            splitViewManager.splitViewController = splitViewController
            setupBehaviour(orientation: interfaceOrientation)
        }
        .mailCustomAlert(isPresented: $mainViewState.isShowingReviewAlert) {
            AskForReviewView(
                appName: Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String,
                reviewManager: reviewManager,
                onLike: {
                    matomo.track(eventWithCategory: .appReview, name: "like")
                    reviewManager.requestReview()
                },
                onDislike: {
                    matomo.track(eventWithCategory: .appReview, name: "dislike")
                }
            )
        }
        .environmentObject(splitViewManager)
        .environmentObject(navigationDrawerState)
        .environmentObject(mailboxManager)
        .environmentObject(ActionsManager(mailboxManager: mailboxManager, mainViewState: mainViewState))
        .environment(\.realmConfiguration, mailboxManager.realmConfiguration)
    }

    private func willEnterForeground() {
        Task {
            // We need to write in Task instead of async let to avoid being cancelled too early
            Task {
                await cacheManager.refreshCacheDataFor(userId: currentUser.value.id)
            }
            Task {
                await fetchFolders()
            }
            Task {
                try await mailboxManager.refreshAllSignatures()
            }
            Task {
                await checkTwoFAChallenges()
            }

            guard !platformDetector.isDebug else { return }
            mainViewState.isShowingSyncDiscovery = platformDetector.isMac ? false : await shouldShowSync()
        }
    }

    private func checkTwoFAChallenges() async {
        @InjectService var accountManager: AccountManager

        let sessions: [InAppTwoFactorAuthenticationSession] = await accountManager.accounts.asyncCompactMap { account in
            guard let user = await accountManager.userProfileStore.getUserProfile(id: account.userId) else {
                return nil
            }

            let apiFetcher = accountManager.getApiFetcher(for: account.userId, token: account)

            let session = InAppTwoFactorAuthenticationSession(user: user, apiFetcher: apiFetcher)
            return session
        }

        @InjectService var inAppTwoFactorAuthenticationManager: InAppTwoFactorAuthenticationManagerable
        inAppTwoFactorAuthenticationManager.checkConnectionAttempts(using: sessions)
    }

    private func setupBehaviour(orientation: UIInterfaceOrientation) {
        if platformDetector.isMac {
            splitViewController?.preferredSplitBehavior = .tile
            splitViewController?.preferredDisplayMode = .twoBesideSecondary
            splitViewController?.presentsWithGesture = false
        } else if orientation.isLandscape {
            splitViewController?.preferredSplitBehavior = .displace
            splitViewController?.preferredDisplayMode = .oneBesideSecondary
        } else if orientation.isPortrait {
            splitViewController?.preferredSplitBehavior = .overlay
            splitViewController?.preferredDisplayMode = .oneOverSecondary
        } else {
            splitViewController?.preferredSplitBehavior = .automatic
            splitViewController?.preferredDisplayMode = .automatic
        }
    }

    private func fetchSignatures() async {
        await tryOrDisplayError {
            try await mailboxManager.refreshAllSignatures()
        }
    }

    private func fetchFolders() async {
        await tryOrDisplayError {
            try await mailboxManager.refreshAllFolders()

            let selectedFolderId = mainViewState.selectedFolder.remoteId
            guard mailboxManager.fetchObject(ofType: Folder.self, forPrimaryKey: selectedFolderId) == nil else {
                return
            }

            if let inboxFolder = mailboxManager.getFolder(with: .inbox)?.freezeIfNeeded() {
                Task { @MainActor in
                    mainViewState.selectedFolder = inboxFolder
                }
            } else {
                throw MailError.folderNotFound
            }
        }
    }

    private func shouldShowSync() async -> Bool {
        guard UserDefaults.shared.shouldPresentSyncDiscovery else { return false }

        guard !mainViewState.isShowingUpdateAvailable else {
            // We don't want to show both DiscoveryView at the same time
            return false
        }

        guard mainViewState.composeMessageIntent == nil else {
            return false
        }

        guard UserDefaults.shared.nextShowSync <= appLaunchCounter.value else {
            return false
        }

        do {
            let syncDate = try await mailboxManager.apiFetcher.lastSyncDate()
            if syncDate == nil {
                UserDefaults.shared.nextShowSync = appLaunchCounter.value + Constants.nextOpeningBeforeSync
                UserDefaults.shared.showSyncCounter += 1
                return true
            } else {
                UserDefaults.shared.shouldPresentSyncDiscovery = false
            }
        } catch {
            Logger.general.error("Error while fetching last sync date: \(error)")
        }
        return false
    }

    private func handleOpenUrl(_ url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        if Constants.isMailTo(url) {
            mainViewState.composeMessageIntent = .mailTo(mailToURLComponents: urlComponents)
        }
    }

    typealias NotificationPublisher = Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue>.Output
    // periphery:ignore:parameters notification - Needed for signature calling in .onReceive
    private func handleCloseDrawer(_ notification: NotificationPublisher) {
        navigationDrawerState.close()
    }

    private func handleApplicationShortcut(_ notification: NotificationPublisher) {
        guard let shortcut = notification.object as? UIApplicationShortcutItem,
              let homeScreenShortcut = HomeScreenShortcut(shortcutItem: shortcut)
        else { return }

        switch homeScreenShortcut {
        case .newMessage:
            mainViewState.composeMessageIntent = .new(originMailboxManager: mailboxManager)
        case .search:
            mainViewState.isShowingSearch = true
        case .support:
            openURL(URLConstants.chatbot.url)
        }

        matomo.track(eventWithCategory: .homeScreenShortcuts, name: homeScreenShortcut.rawValue)
    }

    private func handleShortcutItem() {
        guard let homeScreenShortcut = quickActionsManager.consumeQuickAction() else { return }

        switch homeScreenShortcut {
        case .newMessage:
            mainViewState.composeMessageIntent = .new(originMailboxManager: mailboxManager)
        case .search:
            mainViewState.isShowingSearch = true
        case .support:
            openURL(URLConstants.chatbot.url)
        }

        matomo.track(eventWithCategory: .homeScreenShortcuts, name: homeScreenShortcut.rawValue)
    }

    // periphery:ignore:parameters notification - Needed for signature calling in .onReceive
    private func handleOpenNotificationSettings(_ notification: NotificationPublisher) {
        mainViewState.settingsViewConfig = SettingsViewConfig(baseNavigationPath: [.notifications])
    }
}
