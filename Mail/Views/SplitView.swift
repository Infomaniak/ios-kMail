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

import BottomSheet
import InfomaniakCore
import Introspect
import MailCore
import RealmSwift
import SwiftUI

import MailResources
class GlobalBottomSheet: BottomSheetState<GlobalBottomSheet.State, GlobalBottomSheet.Position> {
    enum State {
        case move(moveHandler: (Folder) -> Void)
        case createNewFolder(mode: CreateFolderView.Mode)
        case getMoreStorage
    }

    enum Position: CGFloat, CaseIterable {
        case moveHeight = 272, newFolderHeight = 300, moreStorageHeight = 480, hidden = 0
    }
}

struct SplitView: View {
    @ObservedObject var mailboxManager = AccountManager.instance.currentMailboxManager!
    @State var selectedFolder: Folder?
    @State var splitViewController: UISplitViewController?
    @StateObject private var navigationDrawerController = NavigationDrawerController()

    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.window) var window

    @StateObject private var menuSheet = MenuSheet()
    @StateObject private var bottomSheet = GlobalBottomSheet()

    private let bottomSheetOptions = Constants.bottomSheetOptions + [.absolutePositionValue, .notResizeable]

    var isCompact: Bool {
        sizeClass == .compact
    }

    init() {
        _selectedFolder = State(wrappedValue: getInbox())
    }

    var body: some View {
        Group {
            if isCompact {
                ZStack {
                    NavigationView {
                        ThreadListView(
                            mailboxManager: mailboxManager,
                            folder: $selectedFolder,
                            isCompact: isCompact
                        )
                    }

                    Group {
                        Color.black
                            .opacity(navigationDrawerController.isOpen ? 0.5 : 0)
                            .ignoresSafeArea()
                            .onTapGesture {
                                navigationDrawerController.close()
                            }

                        NavigationDrawer(
                            mailboxManager: mailboxManager,
                            folder: $selectedFolder,
                            isCompact: isCompact
                        )
                    }
                    .gesture(navigationDrawerController.dragGesture)
                }
            } else {
                NavigationView {
                    MenuDrawerView(
                        mailboxManager: mailboxManager,
                        selectedFolder: $selectedFolder,
                        isCompact: isCompact
                    )
                    .navigationBarHidden(true)

                    ThreadListView(
                        mailboxManager: mailboxManager,
                        folder: $selectedFolder,
                        isCompact: isCompact
                    )

                    EmptyThreadView()
                }
            }
        }
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
            if selectedFolder == nil {
                selectedFolder = getInbox()
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
        .sheet(isPresented: $menuSheet.isShowing) {
            switch menuSheet.state {
            case .newMessage:
                NewMessageView(isPresented: $menuSheet.isShowing, mailboxManager: mailboxManager)
            case let .reply(message, replyMode):
                NewMessageView(isPresented: $menuSheet.isShowing, mailboxManager: mailboxManager, draft: .replying(to: message, mode: replyMode))
            case let .editMessage(draft):
                NewMessageView(isPresented: $menuSheet.isShowing, mailboxManager: mailboxManager, draft: draft.asUnmanaged())
            case .addAccount:
                LoginView(isPresented: $menuSheet.isShowing)
            case .manageAccount:
                AccountView(isPresented: $menuSheet.isShowing)
            case .switchAccount:
                SheetView(isPresented: $menuSheet.isShowing) {
                    AccountListView()
                }
            case .settings:
                SheetView(isPresented: $menuSheet.isShowing) {
                    SettingsView(viewModel: GeneralSettingsViewModel())
                }
            case .none:
                EmptyView()
            }
        }
        .environmentObject(bottomSheet)
        .bottomSheet(bottomSheetPosition: $bottomSheet.position, options: bottomSheetOptions) {
            switch bottomSheet.state {
            case .move(let moveHandler):
                MoveEmailView(mailboxManager: mailboxManager, state: bottomSheet, moveHandler: moveHandler)
            case .createNewFolder(let mode):
                CreateFolderView(mailboxManager: mailboxManager, state: bottomSheet, mode: mode)
            case .getMoreStorage:
                MoreStorageView(state: bottomSheet)
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
