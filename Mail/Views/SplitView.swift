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
    }
}

class GlobalAlert: SheetState<GlobalAlert.State> {
    enum State {
        case createNewFolder(mode: CreateFolderView.Mode)
        case reportPhishing(message: Message)
        case reportDisplayProblem(message: Message)
    }
}

public class SplitViewManager: ObservableObject {
    @Published var showSearch = false
    @Published var selectedFolder: Folder?
    var splitViewController: UISplitViewController?

    init(folder: Folder?) {
        selectedFolder = folder
    }
}

struct SplitView: View {
    var mailboxManager: MailboxManager
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
                        ThreadListManagerView(isCompact: isCompact)
                            .accessibilityHidden(navigationDrawerController.isOpen)
                    }
                    .navigationViewStyle(.stack)

                    NavigationDrawer()
                }
            } else {
                NavigationView {
                    MenuDrawerView(
                        mailboxManager: mailboxManager,
                        isCompact: isCompact
                    )
                    .navigationBarHidden(true)

                    ThreadListManagerView(isCompact: isCompact)

                    EmptyStateView.emptyThread(from: splitViewManager.selectedFolder)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                try await mailboxManager.folders()
            }
        }
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
        .introspectSplitViewController { splitViewController in
            guard let interfaceOrientation = window?.windowScene?.interfaceOrientation,
                  self.splitViewController != splitViewController else { return }
            self.splitViewController = splitViewController
            splitViewManager.splitViewController = splitViewController
            setupBehaviour(orientation: interfaceOrientation)
            splitViewController.preferredDisplayMode = .twoDisplaceSecondary
        }
        .floatingPanel(state: bottomSheet) {
            switch bottomSheet.state {
            case .getMoreStorage:
                MoreStorageView()
            case .restoreEmails:
                RestoreEmailsView(mailboxManager: mailboxManager)
            case .reportJunk(let threadBottomSheet, let target):
                ReportJunkView(
                    mailboxManager: mailboxManager,
                    target: target,
                    state: threadBottomSheet,
                    globalSheet: bottomSheet,
                    globalAlert: alert
                )
            case .none:
                EmptyView()
            }
        }
        .customAlert(isPresented: $alert.isShowing) {
            switch alert.state {
            case .createNewFolder(let mode):
                CreateFolderView(mode: mode)
            case .reportPhishing(let message):
                ReportPhishingView(mailboxManager: mailboxManager, message: message)
            case .reportDisplayProblem(let message):
                ReportDisplayProblemView(mailboxManager: mailboxManager, message: message)
            case .none:
                EmptyView()
            }
        }
        .environment(\.realmConfiguration, mailboxManager.realmConfiguration)
        .environmentObject(mailboxManager)
        .environmentObject(splitViewManager)
        .environmentObject(navigationDrawerController)
        .environmentObject(bottomSheet)
        .environmentObject(alert)
        .defaultAppStorage(.shared)
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
