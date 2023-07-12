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

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var splitViewManager: SplitViewManager
    @EnvironmentObject private var navigationDrawerState: NavigationDrawerState

    @GestureState private var isDragGestureActive = false

    @State private var offsetWidth: CGFloat = 0

    @LazyInjectService private var matomo: MatomoUtils

    var body: some View {
        GeometryReader { rootViewSizeProxy in
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
                        MenuDrawerView()
                            .frame(maxWidth: maxWidth)
                            .padding(.trailing, spacing)
                            .offset(x: navigationDrawerState.isOpen ? offsetWidth : -geometryProxy.size.width)
                        Spacer()
                    }
                }
            }
            .accessibilityAction(.escape) {
                matomo.track(eventWithCategory: .menuDrawer, name: "closeByAccessibility")
                navigationDrawerState.close()
            }
            .gesture(dragGestureForRootViewSize(rootViewSizeProxy.size))
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

    func dragGestureForRootViewSize(_ size: CGSize) -> some Gesture {
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
                if navigationDrawerState.isOpen && value.translation.width < -(size.width / 2) {
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
}

struct MenuDrawerView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var splitViewManager: SplitViewManager
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingRestoreMails = false

    var body: some View {
        VStack(spacing: 0) {
            MenuHeaderView()
                .zIndex(1)

            ScrollView {
                VStack(spacing: 0) {
                    MailboxesManagementView()

                    IKDivider(hasVerticalPadding: true, horizontalPadding: UIConstants.menuDrawerHorizontalPadding)

                    FolderListView(mailboxManager: mailboxManager)

                    IKDivider(hasVerticalPadding: true, horizontalPadding: UIConstants.menuDrawerHorizontalPadding)

                    MenuDrawerItemsAdvancedListView(
                        mailboxCanRestoreEmails: mailboxManager.mailbox.permissions?.canRestoreEmails == true
                    )

                    IKDivider(hasVerticalPadding: true, horizontalPadding: UIConstants.menuDrawerHorizontalPadding)

                    MenuDrawerItemsHelpListView()
                    if mailboxManager.mailbox.isLimited, let quotas = mailboxManager.mailbox.quotas {
                        IKDivider(hasVerticalPadding: true, horizontalPadding: UIConstants.menuDrawerHorizontalPadding)

                        MailboxQuotaView(quotas: quotas)
                    }

                    IKDivider(hasVerticalPadding: true, horizontalPadding: UIConstants.menuDrawerHorizontalPadding)

                    AppVersionView()
                }
                .padding(.vertical, 16)
            }
        }
        .background(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor.ignoresSafeArea())
        .environment(\.folderCellType, .link)
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
        MenuDrawerView()
            .environmentObject(PreviewHelper.sampleMailboxManager)
            .environmentObject(NavigationDrawerState())
    }
}
