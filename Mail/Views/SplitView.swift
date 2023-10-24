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

import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import NavigationBackport
import RealmSwift
import SwiftUI
import VersionChecker

@_spi(Advanced) import SwiftUIIntrospect

public class SplitViewManager: ObservableObject {
    @LazyInjectService private var platformDetector: PlatformDetectable

    @Published var showSearch = false
    @Published var showReviewAlert = false
    @Published var selectedFolder: Folder?
    var splitViewController: UISplitViewController?

    func adaptToProminentThreadView() {
        guard !platformDetector.isMacCatalyst, !platformDetector.isiOSAppOnMac else {
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
    @Environment(\.isCompactWindow) private var isCompactWindow
    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject private var navigationState: NavigationState

    @Weak private var splitViewController: UISplitViewController?

    @StateObject private var navigationDrawerController = NavigationDrawerState()
    @StateObject private var splitViewManager: SplitViewManager

    @LazyInjectService private var orientationManager: OrientationManageable
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable
    @LazyInjectService private var platformDetector: PlatformDetectable
    @LazyInjectService private var appLaunchCounter: AppLaunchCounter

    @State private var isShowingUpdateAvailable = false
    @State private var isShowingSyncDiscovery = false
    @State private var isShowingSyncProfile = false

    let mailboxManager: MailboxManager
    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
        let splitViewManager = SplitViewManager()
        splitViewManager.selectedFolder = mailboxManager.getFolder(with: .inbox)
        _splitViewManager = StateObject(wrappedValue: splitViewManager)
    }

    var body: some View {
        Group {
            if isCompactWindow {
                ZStack {
                    NBNavigationStack(path: $navigationState.threadPath) {
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
                        .navigationBarHidden(!(platformDetector.isMacCatalyst || platformDetector.isiOSAppOnMac))

                    ThreadListManagerView()

                    if let thread = navigationState.threadPath.last {
                        ThreadView(thread: thread)
                    } else {
                        EmptyStateView.emptyThread(from: splitViewManager.selectedFolder)
                    }
                }
            }
        }
        .discoveryPresenter(isPresented: $isShowingUpdateAvailable) {
            DiscoveryView(item: .updateDiscovery) { /* Empty on purpose */ } completionHandler: { update in
                guard update else { return }
                let url: URLConstants = Bundle.main.isRunningInTestFlight ? .testFlight : .appStore
                openURL(url.url)
            }
        }
        .discoveryPresenter(isPresented: $isShowingSyncDiscovery) {
            DiscoveryView(item: .syncDiscovery) {
                UserDefaults.shared.shouldPresentSyncDiscovery = false
            } completionHandler: { update in
                guard update else { return }
                isShowingSyncProfile = true
            }
        }
        .sheet(isPresented: $isShowingSyncProfile) {
            SyncProfileNavigationView()
        }
        .sheet(item: $navigationState.editedDraft) { editedDraft in
            ComposeMessageView(editedDraft: editedDraft, mailboxManager: mailboxManager)
        }
        .onChange(of: scenePhase) { newScenePhase in
            guard newScenePhase == .active else { return }
            Task {
                async let _ = try? mailboxManager.refreshAllFolders()
                async let _ = try? mailboxManager.refreshAllSignatures()

                guard !platformDetector.isDebug else { return }
                // We don't want to show both DiscoveryView at the same time
                isShowingUpdateAvailable = try await VersionChecker.standard.showUpdateVersion()
                isShowingSyncDiscovery = isShowingUpdateAvailable ? false : showSync()
            }
        }
        .onOpenURL { url in
            handleOpenUrl(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .onUserTappedNotification)
            .receive(on: RunLoop.main)) { notification in
                guard let notificationPayload = notification.object as? NotificationTappedPayload else { return }
                let realm = mailboxManager.getRealm()
                realm.refresh()

                navigationDrawerController.close()

                let tappedNotificationMessage = realm.object(ofType: Message.self, forPrimaryKey: notificationPayload.messageId)?
                    .freezeIfNeeded()
                // Original parent should always be in the inbox but maybe change in a later stage to always find the parent in
                // inbox
                if let tappedNotificationThread = tappedNotificationMessage?.originalThread {
                    navigationState.threadPath = [tappedNotificationThread]
                } else {
                    snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription)
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onUserTappedReplyToNotification)
            .receive(on: RunLoop.main)) { notification in
                guard let notificationPayload = notification.object as? NotificationTappedPayload else { return }
                let realm = mailboxManager.getRealm()
                realm.refresh()

                navigationDrawerController.close()

                let tappedNotificationMessage = realm.object(ofType: Message.self, forPrimaryKey: notificationPayload.messageId)?
                    .freezeIfNeeded()
                if let tappedNotificationMessage {
                    navigationState.editedDraft = EditedDraft.replying(
                        reply: MessageReply(message: tappedNotificationMessage, replyMode: .reply),
                        currentMailboxEmail: mailboxManager.mailbox.email
                    )
                } else {
                    snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription)
                }
        }
        .onAppear {
            orientationManager.setOrientationLock(.all)
        }
        .task(id: mailboxManager.mailbox.objectId) {
            await fetchSignatures()
        }
        .task(id: mailboxManager.mailbox.objectId) {
            await fetchFolders()

            let newInbox = getInbox()
            if newInbox != splitViewManager.selectedFolder {
                splitViewManager.selectedFolder = newInbox
            }
        }
        .onRotate { orientation in
            guard let interfaceOrientation = orientation else { return }
            setupBehaviour(orientation: interfaceOrientation)
        }
        .introspect(.navigationView(style: .columns), on: .iOS(.v15, .v16, .v17)) { splitViewController in
            guard let interfaceOrientation = splitViewController.view.window?.windowScene?.interfaceOrientation else { return }
            self.splitViewController = splitViewController
            splitViewManager.splitViewController = splitViewController
            setupBehaviour(orientation: interfaceOrientation)
        }
        .customAlert(isPresented: $splitViewManager.showReviewAlert) {
            AskForReviewView()
        }
        .environmentObject(splitViewManager)
        .environmentObject(navigationDrawerController)
        .environmentObject(mailboxManager)
        .environmentObject(ActionsManager(mailboxManager: mailboxManager, navigationState: navigationState))
        .environment(\.realmConfiguration, mailboxManager.realmConfiguration)
    }

    private func setupBehaviour(orientation: UIInterfaceOrientation) {
        if platformDetector.isMacCatalyst || platformDetector.isiOSAppOnMac {
            splitViewController?.preferredSplitBehavior = .tile
            splitViewController?.preferredDisplayMode = .twoBesideSecondary
        } else if orientation.isLandscape {
            splitViewController?.preferredSplitBehavior = .displace
            splitViewController?.preferredDisplayMode = splitViewManager.selectedFolder == nil
                ? .twoDisplaceSecondary
                : .oneBesideSecondary
        } else if orientation.isPortrait {
            splitViewController?.preferredSplitBehavior = .overlay
            splitViewController?.preferredDisplayMode = splitViewManager.selectedFolder == nil
                ? .twoOverSecondary
                : .oneOverSecondary
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
        }
    }

    private func getInbox() -> Folder? {
        return mailboxManager.getFolder(with: .inbox)
    }

    private func handleOpenUrl(_ url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        if Constants.isMailTo(url) {
            navigationState.editedDraft = EditedDraft.mailTo(urlComponents: urlComponents)
        }
    }

    private func showSync() -> Bool {
        guard UserDefaults.shared.shouldPresentSyncDiscovery,
              !appLaunchCounter.isFirstLaunch else {
            return false
        }

        return appLaunchCounter.value > Constants.minimumOpeningBeforeSync
    }
}
