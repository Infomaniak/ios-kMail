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
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct NavigationDrawer: View {
    private let maxWidth = 350.0
    private let spacing = 60.0

    let mailboxManager: MailboxManager
    let isCompact: Bool

    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var navigationDrawerController: NavigationDrawerController

    var body: some View {
        GeometryReader { geometryProxy in
            HStack {
                MenuDrawerView(
                    mailboxManager: mailboxManager,
                    showMailboxes: $navigationDrawerController.showMailboxes,
                    isCompact: isCompact
                )
                .frame(maxWidth: maxWidth)
                .padding(.trailing, spacing)
                .offset(x: navigationDrawerController.getOffset(size: geometryProxy.size).width)
                Spacer()
            }
        }
    }
}

class NavigationDrawerController: ObservableObject {
    @Published private(set) var isOpen = false
    @Published private(set) var isDragging = false
    @Published private(set) var dragOffset = CGSize.zero

    @Published var showMailboxes = false

    weak var window: UIWindow?

    lazy var dragGesture = DragGesture()
        .onChanged { [weak self] value in
            guard let self = self else { return }
            if (self.isOpen && value.translation.width < 0) || !self.isOpen {
                self.isDragging = true
                self.dragOffset = value.translation
            }
        }
        .onEnded { [weak self] value in
            guard let self = self else { return }
            let windowSize = self.window?.frame.size ?? .zero
            if self.isOpen && value.translation.width < -(windowSize.width / 2) {
                // Closing drawer
                withAnimation {
                    self.dragOffset = CGSize(width: -windowSize.width, height: -windowSize.height)
                }
                self.close()
                self.isDragging = false
            } else {
                withAnimation {
                    self.dragOffset = .zero
                }
                self.isDragging = false
            }
        }

    func getOffset(size: CGSize) -> CGSize {
        if isDragging {
            return dragOffset
        } else if isOpen {
            return .zero
        } else {
            return CGSize(width: -size.width, height: -size.height)
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

struct MenuDrawerView: View {
    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var menuSheet: MenuSheet
    @EnvironmentObject var bottomSheet: GlobalBottomSheet

    @StateObject var viewModel: MenuDrawerViewModel

    var mailboxManager: MailboxManager
    @Binding private var showMailboxes: Bool

    var isCompact: Bool

    init(mailboxManager: MailboxManager, showMailboxes: Binding<Bool>, isCompact: Bool) {
        _viewModel = StateObject(wrappedValue: MenuDrawerViewModel(mailboxManager: mailboxManager))
        self.mailboxManager = mailboxManager
        _showMailboxes = showMailboxes
        self.isCompact = isCompact
    }

    var body: some View {
        VStack(spacing: 0) {
            MenuHeaderView()
                .zIndex(1)

            ScrollView {
                VStack(spacing: 0) {
                    MailboxesManagementView(isExpanded: $showMailboxes,
                                            mailboxes: viewModel.mailboxes)

                    RoleFoldersListView(
                        folders: viewModel.roleFolders,
                        isCompact: isCompact
                    )

                    IKDivider(withPadding: true)

                    UserFoldersListView(
                        folders: viewModel.userFolders,
                        isCompact: isCompact
                    )

                    IKDivider(withPadding: true)

                    MenuDrawerItemsListView(content: viewModel.helpMenuItems)

                    IKDivider(withPadding: true)

                    MenuDrawerItemsListView(
                        title: MailResourcesStrings.Localizable.menuDrawerAdvancedActions,
                        content: viewModel.actionsMenuItems
                    )

                    if viewModel.mailbox.isLimited, let quotas = viewModel.mailbox.quotas {
                        IKDivider(withPadding: true)

                        MailboxQuotaView(quotas: quotas)
                    }
                }
            }
        }
        .background(MailResourcesAsset.backgroundMenuDrawer.swiftUiColor)
        .environmentObject(mailboxManager)
        .onAppear {
            MatomoUtils.track(view: ["MenuDrawer"])
            viewModel.createMenuItems(with: menuSheet, bottomSheet: bottomSheet)
        }
    }
}

struct MenuDrawerView_Previews: PreviewProvider {
    static var previews: some View {
        MenuDrawerView(mailboxManager: PreviewHelper.sampleMailboxManager,
                       showMailboxes: .constant(false),
                       isCompact: false)
    }
}
