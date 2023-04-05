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
import RealmSwift
import SwiftUI

class NavigationDrawerState: ObservableObject {
    @Published private(set) var isOpen = false
    @Published var showMailboxes = false

    func close() {
        withAnimation {
            isOpen = false
        }
    }

    func open() {
        showMailboxes = false
        withAnimation {
            isOpen = true
        }
    }
}

struct NavigationDrawer: View {
    private let maxWidth = 350.0
    private let spacing = 60.0

    let mailboxManager: MailboxManager

    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var navigationDrawerState: NavigationDrawerState
    @Environment(\.window) var window
    @GestureState var isDragGestureActive = false

    @State private var offsetWidth: CGFloat = 0

    @LazyInjectService private var matomo: MatomoUtils

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($isDragGestureActive) { _, active, _ in
                active = true
            }
            .onChanged { value in
                if (navigationDrawerState.isOpen && value.translation.width < 0) || !navigationDrawerState.isOpen {
                    offsetWidth = value.translation.width
                }
            }
            .onEnded { value in
                let windowWidth = window?.frame.size.width ?? 0
                if navigationDrawerState.isOpen && value.translation.width < -(windowWidth / 2) {
                    matomo.track(eventWithCategory: .menuDrawer, name: "closeByGesture")
                    navigationDrawerState.close()
                } else {
                    // Reset drawer to fully open position
                    withAnimation {
                        offsetWidth = 0
                    }
                }
            }
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(navigationDrawerState.isOpen ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    matomo.track(eventWithCategory: .menuDrawer, name: "closeByTap")
                    navigationDrawerState.close()
                }

            GeometryReader { geometryProxy in
                HStack {
                    MenuDrawerView(
                        mailboxManager: mailboxManager,
                        isCompact: true
                    )
                    .frame(maxWidth: maxWidth)
                    .padding(.trailing, spacing)
                    .offset(x: navigationDrawerState.isOpen ? offsetWidth : -geometryProxy.size.width)
                    Spacer()
                }
            }
        }
        .gesture(dragGesture)
        .statusBarHidden(navigationDrawerState.isOpen)
        .onChange(of: navigationDrawerState.isOpen) { isOpen in
            if !isOpen {
                offsetWidth = 0
            }
        }
        .onChange(of: isDragGestureActive) { newIsDragGestureActive in
            if !newIsDragGestureActive && navigationDrawerState.isOpen {
                withAnimation {
                    offsetWidth = 0
                }
            }
        }
    }
}

struct MenuDrawerView: View {
    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var bottomSheet: GlobalBottomSheet

    @StateObject var viewModel: MenuDrawerViewModel

    @LazyInjectService private var matomo: MatomoUtils

    var mailboxManager: MailboxManager

    var isCompact: Bool

    init(mailboxManager: MailboxManager, isCompact: Bool) {
        _viewModel = StateObject(wrappedValue: MenuDrawerViewModel(mailboxManager: mailboxManager))
        self.mailboxManager = mailboxManager
        self.isCompact = isCompact
    }

    var body: some View {
        VStack(spacing: 0) {
            MenuHeaderView()
                .zIndex(1)

            ScrollView {
                VStack(spacing: 0) {
                    Group {
                        MailboxesManagementView(mailboxes: viewModel.mailboxes)

                        IKDivider(hasVerticalPadding: true, horizontalPadding: 24)

                        RoleFoldersListView(folders: viewModel.roleFolders, isCompact: isCompact)

                        IKDivider(hasVerticalPadding: true, horizontalPadding: 24)

                        UserFoldersListView(folders: viewModel.userFolders, isCompact: isCompact)

                        IKDivider(hasVerticalPadding: true, horizontalPadding: 24)
                    }
                    Group {
                        MenuDrawerItemsListView(
                            title: MailResourcesStrings.Localizable.menuDrawerAdvancedActions,
                            content: viewModel.actionsMenuItems,
                            matomoName: "advancedActions"
                        )

                        IKDivider(hasVerticalPadding: true, horizontalPadding: 24)

                        MenuDrawerItemsListView(content: viewModel.helpMenuItems)

                        if viewModel.mailbox.isLimited, let quotas = viewModel.mailbox.quotas {
                            IKDivider(hasVerticalPadding: true, horizontalPadding: 24)

                            MailboxQuotaView(quotas: quotas)
                        }

                        IKDivider(hasVerticalPadding: true, horizontalPadding: 24)

                        AppVersionView()
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .background(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor.ignoresSafeArea())
        .environmentObject(mailboxManager)
        .environment(\.folderCellType, .link)
        .onAppear {
            viewModel.createMenuItems(bottomSheet: bottomSheet)
        }
        .sheet(isPresented: $viewModel.isShowingHelp) {
            SheetView(mailboxManager: mailboxManager) {
                HelpView()
            }
        }
        .sheet(isPresented: $viewModel.isShowingBugTracker) {
            BugTrackerView(isPresented: $viewModel.isShowingBugTracker)
        }
    }
}

struct AppVersionView: View {
    var body: some View {
        Text(Constants.appVersion())
            .textStyle(.labelSecondary)
    }
}

struct MenuDrawerView_Previews: PreviewProvider {
    static var previews: some View {
        MenuDrawerView(mailboxManager: PreviewHelper.sampleMailboxManager, isCompact: false)
            .environmentObject(NavigationDrawerState())
            .environmentObject(GlobalBottomSheet())
    }
}
