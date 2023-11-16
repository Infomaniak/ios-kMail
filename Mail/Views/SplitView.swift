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

import Combine
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

    @EnvironmentObject private var mainViewState: MainViewState

    @Weak private var splitViewController: UISplitViewController?

    @StateObject private var navigationDrawerController = NavigationDrawerState()
    @StateObject private var splitViewManager = SplitViewManager()

    @LazyInjectService private var accountManager: AccountManager
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
    }

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
                        .navigationBarHidden(!(platformDetector.isMacCatalyst || platformDetector.isiOSAppOnMac))

                    ThreadListManagerView()

                    if let thread = mainViewState.threadPath.last {
                        ThreadView(thread: thread)
                    } else {
                        EmptyStateView.emptyThread(from: mainViewState.selectedFolder)
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
        .sheet(item: $mainViewState.editedDraft) { editedDraft in
            ComposeMessageView(editedDraft: editedDraft, mailboxManager: mailboxManager)
        }
        .onChange(of: scenePhase) { newScenePhase in
            guard newScenePhase == .active else { return }
            Task {
                // We need to write in Task instead of async let to avoid being cancelled to early
                Task {
                    try await mailboxManager.refreshAllFolders()
                }
                Task {
                    try await mailboxManager.refreshAllSignatures()
                }
                guard !platformDetector.isDebug else { return }
                // We don't want to show both DiscoveryView at the same time
                isShowingUpdateAvailable = try await VersionChecker.standard.showUpdateVersion()
                isShowingSyncDiscovery = isShowingUpdateAvailable ? false : showSync()
            }
        }
        .onOpenURL { url in
            handleOpenUrl(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .onUserTappedNotification).receive(on: DispatchQueue.main),
                   perform: handleNotification)
        .onReceive(NotificationCenter.default.publisher(for: .onUserTappedReplyToNotification).receive(on: DispatchQueue.main),
                   perform: handleNotification)
        .onAppear {
            orientationManager.setOrientationLock(.all)
        }
        .task(id: mailboxManager.mailbox.objectId) {
            await fetchSignatures()
        }
        .task(id: mailboxManager.mailbox.objectId) {
            await fetchFolders()

            let newInbox = getInbox()
            if newInbox != mainViewState.selectedFolder {
                mainViewState.selectedFolder = newInbox
            }
        }
        .onRotate { orientation in
            guard let interfaceOrientation = orientation else { return }
            setupBehaviour(orientation: interfaceOrientation)
        }
        .introspect(.navigationView(style: .columns), on: .iOS(.v15, .v16, .v17)) { splitViewController in
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
        if platformDetector.isMacCatalyst || platformDetector.isiOSAppOnMac {
            splitViewController?.preferredSplitBehavior = .tile
            splitViewController?.preferredDisplayMode = .twoBesideSecondary
        } else if orientation.isLandscape {
            splitViewController?.preferredSplitBehavior = .displace
            splitViewController?.preferredDisplayMode = mainViewState.selectedFolder == nil
                ? .twoDisplaceSecondary
                : .oneBesideSecondary
        } else if orientation.isPortrait {
            splitViewController?.preferredSplitBehavior = .overlay
            splitViewController?.preferredDisplayMode = mainViewState.selectedFolder == nil
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
            mainViewState.editedDraft = EditedDraft.mailTo(urlComponents: urlComponents)
        }
    }

    private func showSync() -> Bool {
        guard UserDefaults.shared.shouldPresentSyncDiscovery,
              !appLaunchCounter.isFirstLaunch else {
            return false
        }

        return appLaunchCounter.value > Constants.minimumOpeningBeforeSync
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

            let realm = notificationMailboxManager.getRealm()

            let tappedNotificationMessage = realm.object(ofType: Message.self, forPrimaryKey: notificationPayload.messageId)?
                .freezeIfNeeded()
            if notification.name == .onUserTappedNotification {
                // Original parent should always be in the inbox but maybe change in a later stage to always find the parent in
                // inbox
                if let tappedNotificationThread = tappedNotificationMessage?.originalThread {
                    mainViewState.threadPath = [tappedNotificationThread]
                } else {
                    snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription)
                }
            } else if notification.name == .onUserTappedReplyToNotification {
                if let tappedNotificationMessage {
                    mainViewState.editedDraft = EditedDraft.replying(
                        reply: MessageReply(message: tappedNotificationMessage, replyMode: .reply),
                        currentMailboxEmail: mailboxManager.mailbox.email
                    )
                } else {
                    snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription)
                }
            }
        }
    }
}
