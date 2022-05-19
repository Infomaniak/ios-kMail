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

import Introspect
import MailCore
import RealmSwift
import SwiftUI

import MailResources

class SettingsSheet: SheetState<SettingsSheet.State> {
    enum State: Equatable {
        case manageAccount
        case settings
    }
}

struct SplitView: View {
    @ObservedObject var mailboxManager = AccountManager.instance.currentMailboxManager!
    @State var selectedFolder: Folder?
    @State var splitViewController: UISplitViewController?
    @Environment(\.horizontalSizeClass) var sizeClass

    @ObservedObject var settingsSheet = SettingsSheet()
    @ObservedObject var menuSheet = MenuSheet()

    var isCompact: Bool {
        sizeClass == .compact
    }

    init() {
        _selectedFolder = State(wrappedValue: getInbox())
    }

    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                if isCompact {
                    ThreadListView(
                        mailboxManager: mailboxManager,
                        folder: $selectedFolder,
                        isCompact: isCompact,
                        geometryProxy: geometry
                    )
                } else {
                    MenuDrawerView(
                        mailboxManager: mailboxManager,
                        selectedFolder: $selectedFolder,
                        isCompact: isCompact,
                        geometryProxy: geometry
                    )
                    .navigationBarHidden(true)

                    ThreadListView(
                        mailboxManager: mailboxManager,
                        folder: $selectedFolder,
                        isCompact: isCompact,
                        geometryProxy: geometry
                    )

                    EmptyThreadView()
                }
            }
        }
        .environmentObject(menuSheet)
        .environmentObject(settingsSheet)
        .accentColor(Color(MailResourcesAsset.primaryTextColor.color))
        .task {
            do {
                try await mailboxManager.signatures()
            } catch {
                print("Error while fetching signatures: \(error)")
            }
        }
        .onRotate { orientation in
            guard let interfaceOrientation = orientation else { return }
            setupBehaviour(orientation: interfaceOrientation)
        }
        .introspectNavigationController { navController in
            guard let splitViewController = navController.splitViewController,
                  let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?
                  .interfaceOrientation else { return }
            self.splitViewController = splitViewController
            setupBehaviour(orientation: interfaceOrientation)
            splitViewController.preferredDisplayMode = .twoDisplaceSecondary
        }
        .task {
            await fetchFolders()
            // On first launch, select inbox
            if selectedFolder == nil {
                selectedFolder = getInbox()
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

    private func fetchFolders() async {
        do {
            try await mailboxManager.folders()
        } catch {
            print("Error while fetching folders: \(error.localizedDescription)")
        }
    }

    private func getInbox() -> Folder? {
        return mailboxManager.getFolder(with: .inbox)
    }
}
