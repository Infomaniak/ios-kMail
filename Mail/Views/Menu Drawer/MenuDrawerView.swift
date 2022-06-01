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

import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct NavigationDrawer: View {
    private let maxWidth = 350.0
    private let spacing = 60.0

    let mailboxManager: MailboxManager
    @Binding var folder: Folder?
    let isCompact: Bool

    @EnvironmentObject var navigationDrawerController: NavigationDrawerController

    var body: some View {
        GeometryReader { geometryProxy in
            HStack {
                MenuDrawerView(mailboxManager: mailboxManager, selectedFolder: $folder, isCompact: isCompact)
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
        withAnimation {
            isOpen = true
        }
    }
}

struct MenuDrawerView: View {
    @Environment(\.openURL) var openURL

    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 }) var folders

    @StateObject var mailboxManager: MailboxManager
    @State private var showMailboxes = false

    @Binding var selectedFolder: Folder?

    var isCompact: Bool

    private var helpMenuItems = [MenuItem]()
    private var actionsMenuItems = [MenuItem]()

    init(mailboxManager: MailboxManager, selectedFolder: Binding<Folder?>, isCompact: Bool) {
        _folders = .init(Folder.self, configuration: AccountManager.instance.currentMailboxManager!.realmConfiguration) {
            $0.parentLink.count == 0
        }
        _mailboxManager = StateObject(wrappedValue: mailboxManager)
        _selectedFolder = selectedFolder
        self.isCompact = isCompact

        getMenuItems()
    }

    var body: some View {
        ScrollView {
            MenuHeaderView()

            VStack(alignment: .leading) {
                MailboxesManagementView()

                SeparatorView()

                RoleFoldersListView(
                    folders: $folders,
                    selectedFolder: $selectedFolder,
                    isCompact: isCompact
                )

                SeparatorView()

                UserFoldersListView(
                    folders: $folders,
                    selectedFolder: $selectedFolder,
                    isCompact: isCompact
                )

                SeparatorView()

                MenuDrawerItemsListView(content: helpMenuItems)

                SeparatorView()

                MenuDrawerItemsListView(title: MailResourcesStrings.menuDrawerAdvancedActions, content: actionsMenuItems)

                if mailboxManager.mailbox.isLimited {
                    SeparatorView()
                    MailboxQuotaView()
                }
            }
            .padding([.leading, .trailing], Constants.menuDrawerHorizontalPadding)
        }
        .background(Color(MailResourcesAsset.backgroundColor.color))
        .environmentObject(mailboxManager)
        .onAppear {
            MatomoUtils.track(view: ["MenuDrawer"])
        }
    }

    // MARK: - Private methods

    private mutating func getMenuItems() {
        helpMenuItems = [
            MenuItem(icon: MailResourcesAsset.feedbacks, label: MailResourcesStrings.buttonFeedbacks, action: sendFeedback),
            MenuItem(icon: MailResourcesAsset.help, label: MailResourcesStrings.buttonHelp, action: openSupport)
        ]
        actionsMenuItems = [
            MenuItem(icon: MailResourcesAsset.drawerDownload, label: MailResourcesStrings.buttonImportEmails, action: importMails),
            MenuItem(
                icon: MailResourcesAsset.restoreArrow,
                label: MailResourcesStrings.buttonRestoreEmails,
                action: restoreMails
            )
        ]
    }

    // MARK: - Menu actions

    func sendFeedback() {
        openURL(URLConstants.feedback.url)
    }

    func openSupport() {
        openURL(URLConstants.support.url)
    }

    func importMails() {
        openURL(URLConstants.importMails.url)
    }

    func restoreMails() {
        // TODO: Display "Restore Mails" view
    }
}
