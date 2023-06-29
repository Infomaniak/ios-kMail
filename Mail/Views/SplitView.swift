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
import Introspect
import MailCore
import MailResources
import NavigationBackport
import RealmSwift
import SwiftUI

public class SplitViewManager: ObservableObject {
    @Published var showSearch = false
    @Published var selectedFolder: Folder?
    var splitViewController: UISplitViewController?
}

struct SplitView: View {
    @Environment(\.isCompactWindow) private var isCompactWindow
    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject private var navigationStore: NavigationStore

    @State private var splitViewController: UISplitViewController?
    @State private var mailToURLComponents: IdentifiableURLComponents?

    @StateObject private var navigationDrawerController = NavigationDrawerState()
    @StateObject private var splitViewManager = SplitViewManager()

    let mailboxManager: MailboxManager

    var body: some View {
        Group {
            if isCompactWindow {
                ZStack {
                    NBNavigationStack(path: $navigationStore.threadPath) {
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
                        .navigationBarHidden(true)

                    ThreadListManagerView()

                    if let thread = navigationStore.threadPath.last {
                        ThreadView(thread: thread)
                    } else {
                        EmptyStateView.emptyThread(from: splitViewManager.selectedFolder)
                    }
                }
            }
        }
        .sheet(item: $navigationStore.messageReply) { messageReply in
            ComposeMessageView.replyOrForwardMessage(messageReply: messageReply, mailboxManager: mailboxManager)
        }
        .sheet(item: $mailToURLComponents) { identifiableURLComponents in
            ComposeMessageView.mailTo(urlComponents: identifiableURLComponents.urlComponents, mailboxManager: mailboxManager)
        }
        .onChange(of: scenePhase) { newScenePhase in
            guard newScenePhase == .active else { return }
            Task {
                try await mailboxManager.folders()
            }
        }
        .onOpenURL { url in
            handleOpenUrl(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .onUserTappedNotification)) { notification in
            guard let notificationPayload = notification.object as? NotificationTappedPayload else { return }
            let realm = mailboxManager.getRealm()
            realm.refresh()

            let tappedNotificationMessage = realm.object(ofType: Message.self, forPrimaryKey: notificationPayload.messageId)
            // Original parent should always be in the inbox but maybe change in a later stage to always find the parent in inbox
            if let tappedNotificationThread = tappedNotificationMessage?.originalThread {
                navigationStore.threadPath = [tappedNotificationThread]
            } else {
                IKSnackBar.showSnackBar(message: MailError.localMessageNotFound.errorDescription)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onOpenedMailTo)) { identifiableURLComponents in
            self.mailToURLComponents = identifiableURLComponents.object as? IdentifiableURLComponents
        }
        .onAppear {
            AppDelegate.orientationLock = .all
        }
        .task(id: mailboxManager.mailbox.objectId) {
            await fetchSignatures()
        }
        .task(id: mailboxManager.mailbox.objectId) {
            await fetchFolders()
            splitViewManager.selectedFolder = getInbox()
        }
        .onRotate { orientation in
            guard let interfaceOrientation = orientation else { return }
            setupBehaviour(orientation: interfaceOrientation)
        }
        .introspectSplitViewController { splitViewController in
            guard let interfaceOrientation = splitViewController.view.window?.windowScene?.interfaceOrientation,
                  self.splitViewController != splitViewController else { return }
            self.splitViewController = splitViewController
            splitViewManager.splitViewController = splitViewController
            setupBehaviour(orientation: interfaceOrientation)
        }
        .environmentObject(splitViewManager)
        .environmentObject(navigationDrawerController)
        .environmentObject(mailboxManager)
        .environment(\.realmConfiguration, mailboxManager.realmConfiguration)
    }

    private func setupBehaviour(orientation: UIInterfaceOrientation) {
        if orientation.isLandscape {
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
            try await mailboxManager.folders()
        }
    }

    private func getInbox() -> Folder? {
        return mailboxManager.getFolder(with: .inbox)
    }

    private func handleOpenUrl(_ url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        if Constants.isMailTo(url) {
            mailToURLComponents = IdentifiableURLComponents(urlComponents: urlComponents)
        }
    }
}
