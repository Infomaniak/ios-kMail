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
        case move(moveHandler: (Folder) -> Void)
        case getMoreStorage
        case restoreEmails
        case reportDisplayProblem(message: Message)
        case reportPhishing(message: Message)
    }
}

class GlobalAlert: SheetState<GlobalAlert.State> {
    enum State {
        case createNewFolder(mode: CreateFolderView.Mode)
    }
}

public class SplitViewManager: ObservableObject {
    @Published var showSearch = false
    @Published var selectedFolder: Folder?

    init(folder: Folder?) {
        selectedFolder = folder
    }
}

struct SplitView: View {
    @ObservedObject var mailboxManager: MailboxManager
    @State var splitViewController: UISplitViewController?
    @StateObject private var navigationDrawerController = NavigationDrawerController()

    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.window) var window

    @StateObject private var menuSheet = MenuSheet()
    @StateObject private var bottomSheet = GlobalBottomSheet()
    @StateObject private var alert = GlobalAlert()

    @StateObject private var splitViewManager: SplitViewManager


    var isCompact: Bool {
        sizeClass == .compact
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

                    Group {
                        Color.black
                            .opacity(navigationDrawerController.isOpen ? 0.5 : 0)
                            .ignoresSafeArea()
                            .onTapGesture {
                                navigationDrawerController.close()
                            }

                        NavigationDrawer(
                            mailboxManager: mailboxManager,
                            isCompact: isCompact
                        )
                    }
                    .gesture(navigationDrawerController.dragGesture)
                }
            } else {
                NavigationView {
                    MenuDrawerView(
                        mailboxManager: mailboxManager,
                        showMailboxes: $navigationDrawerController.showMailboxes,
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
        .environmentObject(menuSheet)
        .environmentObject(navigationDrawerController)
        .defaultAppStorage(.shared)
        .onAppear {
            navigationDrawerController.window = window
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
            setupBehaviour(orientation: interfaceOrientation)
            splitViewController.preferredDisplayMode = .twoDisplaceSecondary
        }
        .sheet(isPresented: $menuSheet.isShowingComposeNewMessageView) {
            NewMessageView(isPresented: $menuSheet.isShowingComposeNewMessageView, mailboxManager: mailboxManager)
        }
        .sheet(isPresented: $menuSheet.isShowingManageAccount) {
            AccountView()
        }
        .sheet(isPresented: $menuSheet.isShowingSettings) {
            SheetView {
                SettingsView(viewModel: GeneralSettingsViewModel())
            }
        }
        .sheet(isPresented: $menuSheet.isShowingSwitchAccount) {
            SheetView {
                SettingsView(viewModel: GeneralSettingsViewModel())
            }
        }
        .sheet(isPresented: $menuSheet.isShowingHelp) {
            SheetView {
                HelpView()
            }
        }
        .sheet(isPresented: $menuSheet.isShowing) {
            switch menuSheet.state {
            case let .reply(message, replyMode):
                // If message doesn't exist anymore try to show the frozen one
                let freshMessage = message.fresh(using: mailboxManager.getRealm()) ?? message
                NewMessageView(
                    isPresented: $menuSheet.isShowing,
                    mailboxManager: mailboxManager,
                    draft: .replying(to: freshMessage, mode: replyMode)
                )
            case let .editMessage(draft):
                NewMessageView(isPresented: $menuSheet.isShowing, mailboxManager: mailboxManager, draft: draft.asUnmanaged())                
            case .bugTracker:
                BugTrackerView(isPresented: $menuSheet.isShowing)
            case .none:
                EmptyView()
            }
        }
        .environmentObject(bottomSheet)
        .environmentObject(alert)
        .floatingPanel(state: bottomSheet) {
            switch bottomSheet.state {
            case let .move(moveHandler):
                MoveEmailView(mailboxManager: mailboxManager, state: bottomSheet, globalAlert: alert, moveHandler: moveHandler)
            case .getMoreStorage:
                MoreStorageView(state: bottomSheet)
            case .restoreEmails:
                RestoreEmailsView(state: bottomSheet, mailboxManager: mailboxManager)
            case let .reportDisplayProblem(message):
                ReportDisplayProblemView(mailboxManager: mailboxManager, state: bottomSheet, message: message)
            case let .reportPhishing(message):
                ReportPhishingView(mailboxManager: mailboxManager, state: bottomSheet, message: message)
            case .none:
                EmptyView()
            }
        }
        .customAlert(isPresented: $alert.isShowing) {
            switch alert.state {
            case let .createNewFolder(mode):
                CreateFolderView(mailboxManager: mailboxManager, state: alert, mode: mode)
            case .none:
                EmptyView()
            }
        }
    }

    private func setupBehaviour(orientation: UIInterfaceOrientation) {
        if orientation.isLandscape {
            splitViewController?.preferredSplitBehavior = .displace
        } else if orientation.isPortrait {
            splitViewController?.preferredSplitBehavior = .overlay
        } else {
            splitViewController?.preferredSplitBehavior = .automatic
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
