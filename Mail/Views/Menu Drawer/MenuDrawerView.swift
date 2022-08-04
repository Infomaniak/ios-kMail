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
    @Binding var folder: Folder?
    let isCompact: Bool

    @EnvironmentObject var navigationDrawerController: NavigationDrawerController

    var body: some View {
        GeometryReader { geometryProxy in
            HStack {
                MenuDrawerView(mailboxManager: mailboxManager, selectedFolder: $folder, showMailboxes: $navigationDrawerController.showMailboxes, isCompact: isCompact)
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
    @Environment(\.openURL) var openURL

    @EnvironmentObject var menuSheet: MenuSheet
    @EnvironmentObject var bottomSheet: GlobalBottomSheet

    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 }) var folders

    @ObservedRealmObject private var mailbox: Mailbox
    @StateObject var mailboxManager: MailboxManager
    @Binding private var showMailboxes: Bool

    @State private var helpMenuItems = [MenuItem]()
    @State private var actionsMenuItems = [MenuItem]()

    @Binding var selectedFolder: Folder?

    var isCompact: Bool

    init(mailboxManager: MailboxManager, selectedFolder: Binding<Folder?>, showMailboxes: Binding<Bool>, isCompact: Bool) {
        _folders = .init(Folder.self, configuration: AccountManager.instance.currentMailboxManager?.realmConfiguration) {
            $0.parentLink.count == 0
        }
        _mailboxManager = StateObject(wrappedValue: mailboxManager)
        _selectedFolder = selectedFolder
        _showMailboxes = showMailboxes
        self.isCompact = isCompact
        if let liveMailbox = MailboxInfosManager.instance.getMailbox(objectId: mailboxManager.mailbox.objectId, freeze: false) {
            mailbox = liveMailbox
        } else {
            mailbox = mailboxManager.mailbox
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            MenuHeaderView()
                .zIndex(1)

            ScrollView {
                MailboxesManagementView(isExpanded: $showMailboxes)

                RoleFoldersListView(
                    folders: $folders,
                    selectedFolder: $selectedFolder,
                    isCompact: isCompact
                )

                IKDivider(withPadding: true)

                UserFoldersListView(
                    folders: $folders,
                    selectedFolder: $selectedFolder,
                    isCompact: isCompact
                )

                IKDivider(withPadding: true)

                MenuDrawerItemsListView(content: helpMenuItems)

                IKDivider(withPadding: true)

                MenuDrawerItemsListView(title: MailResourcesStrings.Localizable.menuDrawerAdvancedActions, content: actionsMenuItems)

                if mailbox.isLimited, let quotas = mailbox.quotas {
                    IKDivider(withPadding: true)

                    MailboxQuotaView(quotas: quotas)
                }
            }
        }
        .background(MailResourcesAsset.backgroundMenuDrawer.swiftUiColor)
        .environmentObject(mailboxManager)
        .onAppear {
            MatomoUtils.track(view: ["MenuDrawer"])
            getMenuItems()
        }
    }

    // MARK: - Private methods

    private func getMenuItems() {
        helpMenuItems = [
            MenuItem(icon: MailResourcesAsset.feedbacks,
                     label: MailResourcesStrings.Localizable.buttonFeedbacks,
                     action: sendFeedback),
            MenuItem(icon: MailResourcesAsset.help,
                     label: MailResourcesStrings.Localizable.buttonHelp,
                     action: openHelp)
        ]

        actionsMenuItems = [
            MenuItem(icon: MailResourcesAsset.drawerDownload,
                     label: MailResourcesStrings.Localizable.buttonImportEmails,
                     action: importMails)
        ]
        if mailbox.permissions?.canRestoreEmails == true {
            actionsMenuItems.append(.init(
                icon: MailResourcesAsset.restoreArrow,
                label: MailResourcesStrings.Localizable.buttonRestoreEmails,
                action: restoreMails
            ))
        }
    }

    // MARK: - Menu actions

    func sendFeedback() {
        if AccountManager.instance.currentAccount?.user?.isStaff == true {
            BugTracker.configureForMail()
            menuSheet.state = .bugTracker
        } else {
            openURL(URLConstants.feedback.url)
        }
    }

    func openHelp() {
        menuSheet.state = .help
    }

    func importMails() {
        openURL(URLConstants.importMails.url)
    }

    func restoreMails() {
        bottomSheet.open(state: .restoreEmails, position: .restoreEmailsHeight)
    }
}

struct MenuDrawerView_Previews: PreviewProvider {
    static var previews: some View {
        MenuDrawerView(mailboxManager: PreviewHelper.sampleMailboxManager,
                       selectedFolder: .constant(nil), showMailboxes: .constant(false),
                       isCompact: false)
    }
}
