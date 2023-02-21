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
import Introspect
import MailCore
import MailResources
import RealmSwift
import SwiftUI

class GlobalBottomSheet: DisplayedFloatingPanelState<GlobalBottomSheet.State> {
    enum State {
        case getMoreStorage
        case restoreEmails
        case reportJunk(threadBottomSheet: ThreadBottomSheet, target: ActionsTarget)
        case reportDisplayProblem(message: Message)
    }
}

class GlobalAlert: SheetState<GlobalAlert.State> {
    enum State {
        case createNewFolder(mode: CreateFolderView.Mode)
        case reportPhishing(message: Message)
    }
}

public class SplitViewManager: ObservableObject {
    @Published var showSearch = false
    @Published var selectedFolder: Folder?
    var splitViewController: UISplitViewController?
    @Published var avatarImage = Image(resource: MailResourcesAsset.placeholderAvatar)

    @Published var keyboardHeight: CGFloat = 0

    init(folder: Folder?) {
        selectedFolder = folder

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handle(keyboardShowNotification:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handle(keyboardHideNotification:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }

    @objc private func handle(keyboardShowNotification notification: Notification) {
        if let userInfo = notification.userInfo,
           let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            keyboardHeight = keyboardFrame.height
        }
    }
    
    @objc private func handle(keyboardHideNotification notification: Notification) {
        keyboardHeight = 0
    }
}

struct SplitView: View {
    @ObservedObject var mailboxManager: MailboxManager
    @State var splitViewController: UISplitViewController?
    @StateObject private var navigationDrawerController = NavigationDrawerState()

    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.window) var window

    @StateObject private var bottomSheet = GlobalBottomSheet()
    @StateObject private var alert = GlobalAlert()

    @StateObject private var splitViewManager: SplitViewManager

    var isCompact: Bool {
        sizeClass == .compact || verticalSizeClass == .compact
    }

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
        _splitViewManager =
            StateObject(wrappedValue: SplitViewManager(folder: mailboxManager.getFolder(with: .inbox, shouldRefresh: true)))
    }

    var body: some View {
        Group {
            if isCompact {
                ZStack {
                    NavigationView {
                        ThreadListManagerView(
                            mailboxManager: mailboxManager,
                            isCompact: isCompact
                        )
                    }
                    .navigationViewStyle(.stack)

                    NavigationDrawer(mailboxManager: mailboxManager)
                }
            } else {
                NavigationView {
                    MenuDrawerView(
                        mailboxManager: mailboxManager,
                        isCompact: isCompact
                    )
                    .navigationBarHidden(true)

                    ThreadListManagerView(
                        mailboxManager: mailboxManager,
                        isCompact: isCompact
                    )

                    EmptyThreadView()
                }
            }
        }
        .environmentObject(splitViewManager)
        .environmentObject(navigationDrawerController)
        .defaultAppStorage(.shared)
        .onAppear {
            AppDelegate.orientationLock = .all
        }
        .task {
            await fetchSignatures()
        }
        .task {
            await fetchFolders()
            // On first launch, select inbox
            if splitViewManager.selectedFolder == nil {
                splitViewManager.selectedFolder = getInbox()
            }
        }
        .onRotate { orientation in
            guard let interfaceOrientation = orientation else { return }
            setupBehaviour(orientation: interfaceOrientation)
        }
        .introspectNavigationController { navController in
            guard let splitViewController = navController.splitViewController,
                  let interfaceOrientation = window?.windowScene?.interfaceOrientation else { return }
            self.splitViewController = splitViewController
            splitViewManager.splitViewController = splitViewController
            setupBehaviour(orientation: interfaceOrientation)
            splitViewController.preferredDisplayMode = .twoDisplaceSecondary
        }
        .environmentObject(bottomSheet)
        .environmentObject(alert)
        .floatingPanel(state: bottomSheet) {
            switch bottomSheet.state {
            case .getMoreStorage:
                MoreStorageView(state: bottomSheet)
            case .restoreEmails:
                RestoreEmailsView(state: bottomSheet, mailboxManager: mailboxManager)
            case let .reportJunk(threadBottomSheet, target):
                ReportJunkView(
                    mailboxManager: mailboxManager,
                    target: target,
                    state: threadBottomSheet,
                    globalSheet: bottomSheet,
                    globalAlert: alert
                )
            case let .reportDisplayProblem(message):
                ReportDisplayProblemView(mailboxManager: mailboxManager, state: bottomSheet, message: message)
            case .none:
                EmptyView()
            }
        }
        .customAlert(isPresented: $alert.isShowing) {
            switch alert.state {
            case let .createNewFolder(mode):
                CreateFolderView(mailboxManager: mailboxManager, state: alert, mode: mode)
            case let .reportPhishing(message):
                ReportPhishingView(mailboxManager: mailboxManager, alert: alert, message: message)
            case .none:
                EmptyView()
            }
        }
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
            try await mailboxManager.signatures()
        }
    }

    private func fetchFolders() async {
        await tryOrDisplayError {
            try await mailboxManager.folders()
        }
    }

    private func getInbox() -> Folder? {
        return mailboxManager.getFolder(with: .inbox, shouldRefresh: true)
    }
}
