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
import Introspect
import MailCore
import MailResources
import NavigationBackport
import RealmSwift
import SwiftUI

public class SplitViewManager: ObservableObject {
    @LazyInjectService private var platformDetector: PlatformDetectable

    @Published var showSearch = false
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
    @Environment(\.isCompactWindow) private var isCompactWindow
    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject private var navigationState: NavigationState

    @State private var splitViewController: UISplitViewController?
    @State private var mailToURLComponents: IdentifiableURLComponents?

    @StateObject private var navigationDrawerController = NavigationDrawerState()
    @StateObject private var splitViewManager = SplitViewManager()

    @LazyInjectService private var orientationManager: OrientationManageable
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable
    @LazyInjectService private var platformDetector: PlatformDetectable

    let mailboxManager: MailboxManager

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
                        .navigationBarHidden(true)

                    ThreadListManagerView()

                    if let thread = navigationState.threadPath.last {
                        ThreadView(thread: thread)
                    } else {
                        EmptyStateView.emptyThread(from: splitViewManager.selectedFolder)
                    }
                }
            }
        }
        .sheet(item: $navigationState.messageReply) { messageReply in
            ComposeMessageView.replyOrForwardMessage(messageReply: messageReply, mailboxManager: mailboxManager)
        }
        .sheet(item: $mailToURLComponents) { identifiableURLComponents in
            ComposeMessageView.mailTo(urlComponents: identifiableURLComponents.urlComponents, mailboxManager: mailboxManager)
        }
        .sheet(item: $navigationState.editedMessageDraft) { editedMessageDraft in
            ComposeMessageView.edit(draft: editedMessageDraft, mailboxManager: mailboxManager)
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

            navigationDrawerController.close()

            let tappedNotificationMessage = realm.object(ofType: Message.self, forPrimaryKey: notificationPayload.messageId)
            // Original parent should always be in the inbox but maybe change in a later stage to always find the parent in inbox
            if let tappedNotificationThread = tappedNotificationMessage?.originalThread {
                navigationState.threadPath = [tappedNotificationThread]
            } else {
                snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onOpenedMailTo)) { identifiableURLComponents in
            mailToURLComponents = identifiableURLComponents.object as? IdentifiableURLComponents
        }
        .onAppear {
            orientationManager.setOrientationLock(.all)
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
