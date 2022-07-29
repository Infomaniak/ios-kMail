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
import Introspect
import MailCore
import MailResources
import RealmSwift
import SwiftUI

class MenuSheet: SheetState<MenuSheet.State> {
    enum State: Equatable {
        case newMessage
        case reply(Message, ReplyMode)
        case editMessage(draft: Draft)
        case manageAccount
        case switchAccount
        case settings
        case help
        case bugTracker
    }
}

class ThreadBottomSheet: BottomSheetState<ThreadBottomSheet.State, ThreadBottomSheet.Position> {
    enum State: Equatable {
        case actions(ActionsTarget)
    }

    public enum Position: CGFloat, CaseIterable {
        case top = 0.975, middle = 0.4, hidden = 0
    }
}

struct ThreadListView: View {
    @StateObject var viewModel: ThreadListViewModel
    @StateObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    @EnvironmentObject var menuSheet: MenuSheet
    @EnvironmentObject var globalBottomSheet: GlobalBottomSheet

    @AppStorage(UserDefaults.shared.key(.threadDensity)) var threadDensity = ThreadDensity.normal

    @Binding var currentFolder: Folder?

    @State private var avatarImage = Image(resource: MailResourcesAsset.placeholderAvatar)
    @StateObject var bottomSheet: ThreadBottomSheet
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var navigationController: UINavigationController?

    let isCompact: Bool

    private let bottomSheetOptions = Constants.bottomSheetOptions + [.appleScrollBehavior]

    init(mailboxManager: MailboxManager, folder: Binding<Folder?>, isCompact: Bool) {
        let threadBottomSheet = ThreadBottomSheet()
        _bottomSheet = StateObject(wrappedValue: threadBottomSheet)
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(mailboxManager: mailboxManager,
                                                                   folder: folder.wrappedValue,
                                                                   bottomSheet: threadBottomSheet))
        _multipleSelectionViewModel = StateObject(wrappedValue: ThreadListMultipleSelectionViewModel(mailboxManager: mailboxManager))
        _currentFolder = folder
        self.isCompact = isCompact

        UITableViewCell.appearance().focusEffect = .none
    }

    var body: some View {
        VStack(spacing: 0) {
            ThreadListHeader(isConnected: $networkMonitor.isConnected,
                             lastUpdate: $viewModel.lastUpdate,
                             unreadCount: Binding(get: {
                                 currentFolder?.unreadCount
                             }, set: { value in
                                 currentFolder?.unreadCount = value
                             }),
                             unreadFilterOn: $viewModel.filterUnreadOn)

            ZStack {
                MailResourcesAsset.backgroundColor.swiftUiColor

                if $viewModel.sections.isEmpty && !viewModel.isLoadingPage {
                    EmptyListView()
                }

                ScrollViewReader { proxy in
                    List {
                        ForEach(viewModel.sections) { section in
                            Section {
                                threadList(threads: section.threads)
                            } header: {
                                if threadDensity != .compact {
                                    Text(section.title)
                                        .textStyle(.calloutSecondary)
                                }
                            }
                        }

                        if viewModel.isLoadingPage {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
                        }
                    }
                    .listStyle(.plain)
                    .onAppear {
                        viewModel.scrollViewProxy = proxy
                    }
                    .introspectTableView { tableView in
                        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
                    }
                }
            }
            .appShadow()
        }
        .backButtonDisplayMode(.minimal)
        .navigationBarAppStyle()
        .introspectNavigationController { navigationController in
            self.navigationController = navigationController
        }
        .modifier(ThreadListToolbar(isCompact: isCompact,
                                    bottomSheet: bottomSheet,
                                    multipleSelectionViewModel: multipleSelectionViewModel,
                                    folder: $viewModel.folder,
                                    avatarImage: $avatarImage))
        .modifyIf(!multipleSelectionViewModel.isEnabled) { view in
            view
                .floatingActionButton(icon: Image(resource: MailResourcesAsset.edit),
                                      title: MailResourcesStrings.Localizable.buttonNewMessage) {
                    menuSheet.state = .newMessage
                }
        }
        .bottomSheet(bottomSheetPosition: $bottomSheet.position, options: bottomSheetOptions) {
            switch bottomSheet.state {
            case let .actions(target):
                if target.isInvalidated {
                    EmptyView()
                } else {
                    ActionsView(mailboxManager: viewModel.mailboxManager,
                                target: target,
                                state: bottomSheet,
                                globalSheet: globalBottomSheet) { message, replyMode in
                        menuSheet.state = .reply(message, replyMode)
                    }
                }
            default:
                EmptyView()
            }
        }
        .onAppear {
            networkMonitor.start()
            viewModel.globalBottomSheet = globalBottomSheet
            viewModel.menuSheet = menuSheet
            viewModel.selectedThread = nil
        }
        .onChange(of: currentFolder) { newFolder in
            guard let folder = newFolder else { return }
            viewModel.updateThreads(with: folder)
        }
        .task {
            if let account = AccountManager.instance.currentAccount {
                avatarImage = await account.user.getAvatar()
            }
            if let folder = currentFolder {
                viewModel.updateThreads(with: folder)
            }
        }
        .refreshable {
            await viewModel.fetchThreads()
        }
    }

    private func threadList(threads: [Thread]) -> some View {
        ForEach(threads) { thread in
            ThreadListCell(viewModel: viewModel,
                           multipleSelectionViewModel: multipleSelectionViewModel,
                           thread: thread,
                           navigationController: navigationController)
            .onAppear {
                viewModel.loadNextPageIfNeeded(currentItem: thread)
            }
            .listRowInsets(.init(top: 0, leading: 8, bottom: 0, trailing: 12))
            .listRowSeparator(.hidden)
            .listRowBackground(viewModel.selectedThread == thread
                ? MailResourcesAsset.backgroundCardSelectedColor.swiftUiColor
                : MailResourcesAsset.backgroundColor.swiftUiColor)
        }
    }
}

private struct ThreadListToolbar: ViewModifier {
    var isCompact: Bool

    @ObservedObject var bottomSheet: ThreadBottomSheet
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    @Binding var folder: Folder?
    @Binding var avatarImage: Image

    @EnvironmentObject var menuSheet: MenuSheet
    @EnvironmentObject var navigationDrawerController: NavigationDrawerController

    @ToolbarContentBuilder
    private var navigationBar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                // TODO: Search
                showWorkInProgressSnackBar()
            } label: {
                Image(resource: MailResourcesAsset.search)
            }

            Button {
                menuSheet.state = .switchAccount
            } label: {
                avatarImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
            }
        }

        ToolbarItem(placement: .principal) {
            Text(folder?.localizedName ?? "")
                .layoutPriority(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textStyle(.header1)
                .padding(.leading, 8)
        }
    }

    @ToolbarContentBuilder
    private var navigationBarCompact: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                navigationDrawerController.open()
            } label: {
                Image(resource: MailResourcesAsset.burger)
            }
        }
    }

    @ToolbarContentBuilder
    private var multipleSelectionNavigationBar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(MailResourcesStrings.Localizable.buttonCancel) {
                multipleSelectionViewModel.isEnabled = false
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(MailResourcesStrings.Localizable.buttonSelectAll) {}
        }

        ToolbarItemGroup(placement: .bottomBar) {
            ForEach(multipleSelectionViewModel.toolbarActions) { action in
                ToolbarButton(text: action.shortTitle ?? action.title, icon: action.icon) {
                    Task {
                        await tryOrDisplayError {
                            try await multipleSelectionViewModel.didTap(action: action)
                        }
                    }
                }
                Spacer()
            }
            ToolbarButton(text: MailResourcesStrings.Localizable.buttonMore, icon: MailResourcesAsset.plusActions) {
                bottomSheet.open(state: .actions(.threads(Array(multipleSelectionViewModel.selectedItems))), position: .middle)
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .modifyIf(!multipleSelectionViewModel.isEnabled) { view in
                view
                    .toolbar { navigationBar }
                    .modifyIf(isCompact) { view in
                        view.toolbar { navigationBarCompact }
                    }
            }
            .modifyIf(multipleSelectionViewModel.isEnabled) { view in
                view
                    .navigationTitle(MailResourcesStrings.Localizable.multipleSelectionCount(multipleSelectionViewModel.selectedItems.count))
                    .toolbar { multipleSelectionNavigationBar }
            }
    }
}

struct ThreadListView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListView(
            mailboxManager: PreviewHelper.sampleMailboxManager,
            folder: .constant(PreviewHelper.sampleFolder),
            isCompact: false
        )
        .environmentObject(MenuSheet())
    }
}
