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
import MailResources
import RealmSwift
import SwiftUI

class MenuSheet: ObservableObject {
    @Published var isShowingComposeNewMessageView = false
    @Published var isShowingManageAccount = false
    @Published var isShowingSettings = false
    @Published var isShowingSwitchAccount = false
    @Published var isShowingHelp = false
    @Published var isShowingBugTracker = false
    @Published var editedMessageDraft: Draft?
    @Published var messageReply: MessageReply?

    struct MessageReply: Identifiable {
        var id: ObjectIdentifier {
            return message.id
        }

        let message: Message
        let replyMode: ReplyMode
    }
}

class ThreadBottomSheet: DisplayedFloatingPanelState<ThreadBottomSheet.State> {
    enum State: Equatable {
        case actions(ActionsTarget)
    }
}

struct ThreadListView: View {
    @StateObject var viewModel: ThreadListViewModel
    @StateObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var menuSheet: MenuSheet
    @EnvironmentObject var globalBottomSheet: GlobalBottomSheet

    @AppStorage(UserDefaults.shared.key(.threadDensity)) var threadDensity = ThreadDensity.normal

    @State private var avatarImage = Image(resource: MailResourcesAsset.placeholderAvatar)
    @StateObject var bottomSheet: ThreadBottomSheet
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var navigationController: UINavigationController?

    let isCompact: Bool

    init(mailboxManager: MailboxManager, folder: Folder?, isCompact: Bool) {
        let threadBottomSheet = ThreadBottomSheet()
        _bottomSheet = StateObject(wrappedValue: threadBottomSheet)
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(mailboxManager: mailboxManager,
                                                                   folder: folder,
                                                                   bottomSheet: threadBottomSheet))
        _multipleSelectionViewModel = StateObject(wrappedValue: ThreadListMultipleSelectionViewModel(mailboxManager: mailboxManager))
        self.isCompact = isCompact

        UITableViewCell.appearance().focusEffect = .none
    }

    var body: some View {
        VStack(spacing: 0) {
            ThreadListHeader(isMultipleSelectionEnabled: multipleSelectionViewModel.isEnabled,
                             isConnected: $networkMonitor.isConnected,
                             lastUpdate: $viewModel.lastUpdate,
                             unreadCount: Binding(get: {
                                 splitViewManager.selectedFolder?.unreadCount
                             }, set: { value in
                                 splitViewManager.selectedFolder?.unreadCount = value
                             }),
                             unreadFilterOn: $viewModel.filterUnreadOn)

            ZStack {
                MailResourcesAsset.backgroundColor.swiftUiColor

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

                        Spacer()
                            .frame(height: multipleSelectionViewModel.isEnabled ? 75 : 85)
                            .listRowSeparator(.hidden)
                            .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
                    }
                    .listStyle(.plain)
                    .onAppear {
                        viewModel.scrollViewProxy = proxy
                    }
                }

                if viewModel.folder?.lastUpdate != nil && viewModel.sections.isEmpty && !viewModel.isLoadingPage {
                    EmptyListView()
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
                                    avatarImage: $avatarImage,
                                    observeThread: $viewModel.observeThread,
                                    navigationController: $navigationController))
        .floatingActionButton(isEnabled: !multipleSelectionViewModel.isEnabled,
                              icon: Image(resource: MailResourcesAsset.edit),
                              title: MailResourcesStrings.Localizable.buttonNewMessage) {
            menuSheet.isShowingComposeNewMessageView.toggle()
        }
        .floatingPanel(state: bottomSheet, halfOpening: true) {
            if case let .actions(target) = bottomSheet.state, !target.isInvalidated {
                ActionsView(mailboxManager: viewModel.mailboxManager,
                            target: target,
                            state: bottomSheet,
                            globalSheet: globalBottomSheet) { message, replyMode in
                    menuSheet.messageReply = MenuSheet.MessageReply(message: message, replyMode: replyMode)
                } completionHandler: {
                    bottomSheet.close()
                    multipleSelectionViewModel.isEnabled = false
                }
            }
        }
        .onAppear {
            networkMonitor.start()
            viewModel.globalBottomSheet = globalBottomSheet
            viewModel.menuSheet = menuSheet
            viewModel.selectedThread = nil
            Task {
                await viewModel.fetchThreads()
            }
        }
        .onChange(of: splitViewManager.selectedFolder) { newFolder in
            guard isCompact, let folder = newFolder else { return }
            viewModel.updateThreads(with: folder)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await viewModel.fetchThreads()
            }
        }
        .task {
            if let account = AccountManager.instance.currentAccount {
                avatarImage = await account.user.getAvatar()
            }
            if let folder = splitViewManager.selectedFolder {
                viewModel.updateThreads(with: folder)
            }
        }
        .refreshable {
            await viewModel.fetchThreads()
        }
    }

    private func threadList(threads: [Thread]) -> some View {
        ForEach(threads) { thread in
            ThreadListCell(thread: thread,
                           viewModel: viewModel,
                           multipleSelectionViewModel: multipleSelectionViewModel,
                           navigationController: navigationController)
        }
    }
}

private struct ThreadListToolbar: ViewModifier {
    var isCompact: Bool

    @ObservedObject var bottomSheet: ThreadBottomSheet
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    @Binding var avatarImage: Image
    @Binding var observeThread: Bool

    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var menuSheet: MenuSheet
    @EnvironmentObject var navigationDrawerController: NavigationDrawerController

    @Binding var navigationController: UINavigationController?

    func body(content: Content) -> some View {
        GeometryReader { reader in
            content
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if multipleSelectionViewModel.isEnabled {
                            Button(MailResourcesStrings.Localizable.buttonCancel) {
                                withAnimation {
                                    multipleSelectionViewModel.isEnabled = false
                                }
                            }
                        } else {
                            if isCompact {
                                Button {
                                    navigationDrawerController.open()
                                } label: {
                                    Image(resource: MailResourcesAsset.burger)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: Constants.navbarIconSize, height: Constants.navbarIconSize)
                                }
                            }
                            Text(splitViewManager.selectedFolder?.localizedName ?? "")
                                .textStyle(.header1)
                                .padding(.leading, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if multipleSelectionViewModel.isEnabled {
                            Button(MailResourcesStrings.Localizable.buttonSelectAll) {
                                // TODO: Select all threads
                                showWorkInProgressSnackBar()
                            }
                        } else {
                            Button {
                                splitViewManager.showSearch = true
                            } label: {
                                Image(resource: MailResourcesAsset.search)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: Constants.navbarIconSize, height: Constants.navbarIconSize)
                            }

                            Button {
                                menuSheet.isShowingSwitchAccount.toggle()
                            } label: {
                                avatarImage
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .clipShape(Circle())
                            }
                        }
                    }

                    ToolbarItemGroup(placement: .bottomBar) {
                        if multipleSelectionViewModel.isEnabled {
                            HStack(spacing: 0) {
                                ForEach(multipleSelectionViewModel.toolbarActions) { action in
                                    ToolbarButton(text: action.shortTitle ?? action.title, icon: action.icon, width: reader.size.width / 5) {
                                        Task {
                                            await tryOrDisplayError {
                                                try await multipleSelectionViewModel.didTap(action: action)
                                            }
                                        }
                                    }
                                }

                                ToolbarButton(text: MailResourcesStrings.Localizable.buttonMore,
                                              icon: MailResourcesAsset.plusActions,
                                              width: reader.size.width / 5) {
                                    bottomSheet.open(state: .actions(.threads(Array(multipleSelectionViewModel.selectedItems))))
                                }
                            }
                        }
                    }
                }
                .navigationTitle(
                    multipleSelectionViewModel.isEnabled
                        ? MailResourcesStrings.Localizable.multipleSelectionCount(multipleSelectionViewModel.selectedItems.count)
                        : ""
                )
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ThreadListView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListView(
            mailboxManager: PreviewHelper.sampleMailboxManager,
            folder: PreviewHelper.sampleFolder,
            isCompact: false
        )
        .environmentObject(MenuSheet())
    }
}
