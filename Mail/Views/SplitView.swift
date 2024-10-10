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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import Lottie
import MailCore
import MailCoreUI
import MailResources
import NavigationBackport
import RealmSwift
import SwiftModalPresentation
import SwiftUI

@_spi(Advanced) import SwiftUIIntrospect

public class SplitViewManager: ObservableObject {
    @LazyInjectService private var platformDetector: PlatformDetectable

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
    @Environment(\.openURL) private var openURL
    @Environment(\.currentUser) private var currentUser
    @Environment(\.isCompactWindow) private var isCompactWindow

    @EnvironmentObject private var mainViewState: MainViewState

    @Weak private var splitViewController: UISplitViewController?

    @StateObject private var navigationDrawerController = NavigationDrawerState()
    @StateObject private var splitViewManager = SplitViewManager()

    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var orientationManager: OrientationManageable
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable
    @LazyInjectService private var platformDetector: PlatformDetectable
    @LazyInjectService private var appLaunchCounter: AppLaunchCounter

    let mailboxManager: MailboxManager

    var body: some View {
        Group {
            if isCompactWindow {
                ZStack {
                    NBNavigationStack(path: $mainViewState.threadPath) {
                        ThreadListManagerView()
                            .accessibilityHidden(navigationDrawerController.isOpen)
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
                        .navigationBarHidden(!platformDetector.isMac)

                    ThreadListManagerView()

                    if let thread = mainViewState.selectedThread {
                        ThreadView(thread: thread)
                    } else {
                        EmptyStateView.emptyThread(from: mainViewState.selectedFolder)
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if EasterEgg.christmas.shouldTrigger() && mainViewState.isShowingChristmasEasterEgg {
                LottieView(animation: LottieAnimation.named("easter_egg_xmas", bundle: MailResourcesResources.bundle))
                    .animationDidFinish { _ in
                        mainViewState.isShowingChristmasEasterEgg = false
                    }
                    .playing(loopMode: .playOnce)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .padding(.bottom, 96)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .onAppear {
                        EasterEgg.christmas.onTrigger()
                    }
            }
        }
        .discoveryPresenter(isPresented: $mainViewState.isShowingUpdateAvailable) {
            DiscoveryView(item: .updateDiscovery) { willUpdate in
                guard willUpdate else { return }
                let url: URLConstants = Bundle.main.isRunningInTestFlight ? .testFlight : .appStore
                openURL(url.url)
            }
        }
        .discoveryPresenter(isPresented: $mainViewState.isShowingSyncDiscovery) {
            DiscoveryView(item: .syncDiscovery) {
                UserDefaults.shared.shouldPresentSyncDiscovery = false
            } completionHandler: { willSync in
                guard willSync else { return }
                mainViewState.isShowingSyncProfile = true
            }
        }
        .discoveryPresenter(isPresented: $mainViewState.isShowingSetAppAsDefaultDiscovery) {
            DiscoveryView(item: .setAsDefaultAppDiscovery) {
                UserDefaults.shared.shouldPresentSetAsDefaultDiscovery = false
            } completionHandler: { willSetAsDefault in
                guard willSetAsDefault, let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(settingsUrl)
            }
        }
        .sheet(isPresented: $mainViewState.isShowingSyncProfile) {
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
        // swiftlint:disable:next trailing_closure
        .sceneLifecycle(willEnterForeground: {
            Task {
                // We need to write in Task instead of async let to avoid being cancelled to early
                Task {
                    await fetchFolders()
                }
                Task {
                    try await mailboxManager.refreshAllSignatures()
                }
                guard !platformDetector.isDebug else { return }
                mainViewState.isShowingSyncDiscovery = platformDetector.isMac ? false : shouldShowSync()
            }
        })
        .onOpenURL { url in
            handleOpenUrl(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .onUserTappedNotification).receive(on: DispatchQueue.main),
                   perform: handleNotification)
        .onReceive(NotificationCenter.default.publisher(for: .onUserTappedReplyToNotification).receive(on: DispatchQueue.main),
                   perform: handleNotification)
        .onReceive(NotificationCenter.default.publisher(for: .openNotificationSettings).receive(on: DispatchQueue.main),
                   perform: handleOpenNotificationSettings)
        .onReceive(NotificationCenter.default.publisher(for: .userPerformedHomeScreenShortcut).receive(on: DispatchQueue.main),
                   perform: handleApplicationShortcut)
        .onAppear {
            orientationManager.setOrientationLock(.all)
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
        .introspect(.navigationView(style: .columns), on: .iOS(.v15, .v16, .v17, .v18)) { splitViewController in
            guard let interfaceOrientation = splitViewController.view.window?.windowScene?.interfaceOrientation else { return }
            guard self.splitViewController != splitViewController else { return }
            self.splitViewController = splitViewController
            splitViewManager.splitViewController = splitViewController
            setupBehaviour(orientation: interfaceOrientation)
        }
        .customAlert(isPresented: $mainViewState.isShowingReviewAlert) {
            AskForReviewView()
        }
        .environmentObject(splitViewManager)
        .environmentObject(navigationDrawerController)
        .environmentObject(mailboxManager)
        .environmentObject(ActionsManager(mailboxManager: mailboxManager, mainViewState: mainViewState))
        .environment(\.realmConfiguration, mailboxManager.realmConfiguration)
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

    private func shouldShowSync() -> Bool {
        guard !mainViewState.isShowingUpdateAvailable else {
            // We don't want to show both DiscoveryView at the same time
            return false
        }
        guard UserDefaults.shared.shouldPresentSyncDiscovery,
              !appLaunchCounter.isFirstLaunch else {
            return false
        }

        return appLaunchCounter.value > Constants.minimumOpeningBeforeSync
    }

    private func handleOpenUrl(_ url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        if Constants.isMailTo(url) {
            mainViewState.composeMessageIntent = .mailTo(mailToURLComponents: urlComponents)
        }
    }

    private func handleApplicationShortcut(_ notification: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue>
        .Output) {
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

        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .homeScreenShortcuts, name: homeScreenShortcut.rawValue)
    }

    private func handleNotification(_ notification: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue>.Output) {
        guard let notificationPayload = notification.object as? NotificationTappedPayload else { return }

        guard let notificationMailboxManager = accountManager.getMailboxManager(for: notificationPayload.mailboxId,
                                                                                userId: notificationPayload.userId)
        else { return }
        navigationDrawerController.close()

        Task {
            // We haven't switched Env yet so we wait a little bit
            if notificationMailboxManager != mailboxManager {
                try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
            }

            let tappedNotificationMessage = notificationMailboxManager.fetchObject(ofType: Message.self,
                                                                                   forPrimaryKey: notificationPayload.messageId)?
                .freezeIfNeeded()

            if notification.name == .onUserTappedNotification {
                // Original parent should always be in the inbox but maybe change in a later stage to always find the parent in
                // inbox
                if let tappedNotificationThread = tappedNotificationMessage?.originalThread {
                    mainViewState.selectedThread = tappedNotificationThread
                } else {
                    snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription ?? "")
                }
            } else if notification.name == .onUserTappedReplyToNotification {
                if let tappedNotificationMessage {
                    mainViewState.composeMessageIntent = .replyingTo(
                        message: tappedNotificationMessage,
                        replyMode: .reply,
                        originMailboxManager: mailboxManager
                    )
                } else {
                    snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription ?? "")
                }
            }
        }
    }

    // periphery:ignore:parameters notification - Needed for signature calling in .onReceive
    private func handleOpenNotificationSettings(_ notification:
        Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue>.Output) {
        mainViewState.settingsViewConfig = SettingsViewConfig(baseNavigationPath: [.notifications])
    }
}
