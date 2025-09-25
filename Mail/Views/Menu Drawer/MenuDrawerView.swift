/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

class NavigationDrawerState: ObservableObject {
    @Published private(set) var isOpen = false
    @Published var showMailboxes = false

    var useNativeToolbar: Bool {
        if #available(iOS 26, *) {
            return true
        } else if InjectService<PlatformDetectable>().wrappedValue.isMac {
            return true
        } else {
            return false
        }
    }

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
    private static let maxWidth: CGFloat = 352
    private static let trailingPadding: CGFloat = 64

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
                            .frame(maxWidth: Self.maxWidth)
                            .padding(.trailing, Self.trailingPadding)
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
    @EnvironmentObject private var mailboxManager: MailboxManager

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                MailboxesManagementView()

                IKDivider(type: .menu)

                FolderListView(mailboxManager: mailboxManager)

                IKDivider(type: .menu)

                MenuDrawerItemsAdvancedListView(
                    mailboxCanRestoreEmails: mailboxManager.mailbox.permissions?.canRestoreEmails == true
                )

                IKDivider(type: .menu)

                MenuDrawerItemsHelpListView()

                if mailboxManager.mailbox.isLimited, let quotas = mailboxManager.mailbox.quotas, quotas.maxStorage != nil {
                    IKDivider(type: .menu)

                    MailboxQuotaView(quotas: quotas)
                }

                IKDivider(type: .menu)

                AppVersionView()
            }
            .padding(.vertical, value: .mini)
            .padding(.leading, value: .mini)
        }
        .menuHeader()
        .environment(\.folderCellType, .menuDrawer)
        .background(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor.ignoresSafeArea())
    }
}

struct AppVersionView: View {
    var body: some View {
        Text(Constants.appVersionLabel)
            .textStyle(.labelSecondary)
    }
}

#Preview {
    MenuDrawerView()
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environmentObject(NavigationDrawerState())
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
