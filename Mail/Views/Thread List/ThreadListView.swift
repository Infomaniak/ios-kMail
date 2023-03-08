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
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

class ThreadBottomSheet: DisplayedFloatingPanelState<ThreadBottomSheet.State> {
    enum State: Equatable {
        case actions(ActionsTarget)
    }
}

class MoveSheet: SheetState<MoveSheet.State> {
    enum State {
        case move(folderId: String?, moveHandler: MoveEmailView.MoveHandler)
    }
}

class FlushAlertState: Identifiable {
    let id = UUID()
    let deletedMessages: Int?
    let completion: () async -> Void

    init(deletedMessages: Int? = nil, completion: @escaping () async -> Void) {
        self.deletedMessages = deletedMessages
        self.completion = completion
    }
}

struct ThreadListView: View {
    @StateObject var viewModel: ThreadListViewModel
    @StateObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var globalBottomSheet: GlobalBottomSheet

    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @State private var isShowingComposeNewMessageView = false
    @StateObject var bottomSheet: ThreadBottomSheet
    @StateObject var moveSheet: MoveSheet
    @StateObject private var networkMonitor = NetworkMonitor()
    @Binding private var editedMessageDraft: Draft?
    @Binding private var messageReply: MessageReply?
    @State private var fetchingTask: Task<Void, Never>?
    @State private var isRefreshing = false
    @State private var firstLaunch = true
    @State private var flushAlert: FlushAlertState?

    let isCompact: Bool

    init(mailboxManager: MailboxManager,
         folder: Folder?,
         editedMessageDraft: Binding<Draft?>,
         messageReply: Binding<MessageReply?>,
         isCompact: Bool) {
        let threadBottomSheet = ThreadBottomSheet()
        let moveEmailSheet = MoveSheet()
        _editedMessageDraft = editedMessageDraft
        _messageReply = messageReply
        _bottomSheet = StateObject(wrappedValue: threadBottomSheet)
        _moveSheet = StateObject(wrappedValue: moveEmailSheet)
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(mailboxManager: mailboxManager,
                                                                   folder: folder,
                                                                   bottomSheet: threadBottomSheet,
                                                                   moveSheet: moveEmailSheet,
                                                                   isCompact: isCompact))
        _multipleSelectionViewModel =
            StateObject(wrappedValue: ThreadListMultipleSelectionViewModel(mailboxManager: mailboxManager))
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
                                 splitViewManager.selectedFolder?.unreadCount = value ?? 0
                             }),
                             unreadFilterOn: $viewModel.filterUnreadOn)

            ScrollViewReader { proxy in
                List {
                    if viewModel.isLoadingPage && !isRefreshing {
                        ProgressView()
                            .id(UUID())
                            .frame(maxWidth: .infinity)
                            .listRowSeparator(.hidden)
                    }

                    if !viewModel.sections.isEmpty,
                       viewModel.folder?.role == .trash || viewModel.folder?.role == .spam,
                       let folder = viewModel.folder {
                        FlushFolderView(folder: folder, mailboxManager: viewModel.mailboxManager, flushAlert: $flushAlert)
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init())
                    }

                    ForEach(viewModel.sections) { section in
                        Section {
                            ForEach(section.threads) { thread in
                                ThreadListCell(thread: thread,
                                               viewModel: viewModel,
                                               multipleSelectionViewModel: multipleSelectionViewModel,
                                               threadDensity: threadDensity,
                                               editedMessageDraft: $editedMessageDraft,
                                               isSelected: multipleSelectionViewModel.selectedItems.contains(thread))
                                    .id(thread.id)
                            }
                        } header: {
                            if threadDensity != .compact {
                                Text(section.title)
                                    .textStyle(.bodySmallSecondary)
                            }
                        }
                    }

                    Spacer()
                        .frame(height: multipleSelectionViewModel.isEnabled ? 100 : 110)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .overlay {
                    if viewModel.folder?.lastUpdate != nil && viewModel.sections.isEmpty && !viewModel.isLoadingPage {
                        EmptyListView(isInbox: viewModel.folder?.role == .inbox)
                    }
                }
                .listStyle(.plain)
                .onAppear {
                    viewModel.scrollViewProxy = proxy
                }
                .appShadow()
            }
        }
        .id("\(accentColor.rawValue) \(threadDensity.rawValue)")
        .backButtonDisplayMode(.minimal)
        .navigationBarThreadListStyle()
        .toolbarAppStyle()
        .refreshable {
            withAnimation {
                isRefreshing = true
            }
            if let fetchingTask {
                _ = await fetchingTask.result
            } else {
                await viewModel.fetchThreads()
            }
            withAnimation {
                isRefreshing = false
            }
        }
        .modifier(ThreadListToolbar(isCompact: isCompact,
                                    flushAlert: $flushAlert,
                                    bottomSheet: bottomSheet,
                                    multipleSelectionViewModel: multipleSelectionViewModel,
                                    selectAll: {
                                        withAnimation(.default.speed(2)) {
                                            multipleSelectionViewModel.selectAll(threads: viewModel.sections.flatMap(\.threads))
                                        }
                                    }))
        .floatingActionButton(isEnabled: !multipleSelectionViewModel.isEnabled,
                              icon: MailResourcesAsset.pencilPlain,
                              title: MailResourcesStrings.Localizable.buttonNewMessage) {
            isShowingComposeNewMessageView.toggle()
        }
        .floatingPanel(state: bottomSheet, halfOpening: true) {
            if case let .actions(target) = bottomSheet.state, !target.isInvalidated {
                ActionsView(mailboxManager: viewModel.mailboxManager,
                            target: target,
                            state: bottomSheet,
                            globalSheet: globalBottomSheet, moveSheet: moveSheet) { message, replyMode in
                    messageReply = MessageReply(message: message, replyMode: replyMode)
                } completionHandler: {
                    bottomSheet.close()
                    multipleSelectionViewModel.isEnabled = false
                }
            }
        }
        .onAppear {
            networkMonitor.start()
            viewModel.globalBottomSheet = globalBottomSheet
            viewModel.selectedThread = nil
        }
        .onChange(of: splitViewManager.selectedFolder) { newFolder in
            changeFolder(newFolder: newFolder)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateFetchingTask()
        }
        .task {
            if let account = AccountManager.instance.currentAccount {
                splitViewManager.avatarImage = await account.user.avatarImage
            }
            if firstLaunch {
                updateFetchingTask()
                firstLaunch = false
            }
        }
        .sheet(isPresented: $isShowingComposeNewMessageView) {
            ComposeMessageView.newMessage(mailboxManager: viewModel.mailboxManager)
        }
        .sheet(isPresented: $moveSheet.isShowing) {
            if case let .move(folderId, handler) = moveSheet.state {
                MoveEmailView.sheetView(mailboxManager: viewModel.mailboxManager, from: folderId, moveHandler: handler)
            }
        }
        .customAlert(item: $flushAlert) { item in
            FlushFolderAlertView(flushAlert: item, folder: viewModel.folder)
        }
        .matomoView(view: [MatomoUtils.View.threadListView.displayName, "Main"])
    }

    private func changeFolder(newFolder: Folder?) {
        guard let folder = newFolder else { return }

        viewModel.isLoadingPage = false
        Task {
            fetchingTask?.cancel()
            _ = await fetchingTask?.result
            fetchingTask = nil
            updateFetchingTask(with: folder)
        }
    }

    private func updateFetchingTask(with folder: Folder? = nil) {
        guard fetchingTask == nil else { return }
        fetchingTask = Task {
            if let folder = folder {
                await viewModel.updateThreads(with: folder)
            } else {
                await viewModel.fetchThreads()
            }
            fetchingTask = nil
        }
    }
}

private struct ThreadListToolbar: ViewModifier {
    var isCompact: Bool

    @Binding var flushAlert: FlushAlertState?

    @ObservedObject var bottomSheet: ThreadBottomSheet
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    @State private var isShowingSwitchAccount = false

    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var navigationDrawerState: NavigationDrawerState

    @LazyInjectService private var matomo: MatomoUtils

    var selectAll: () -> Void

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
                                    matomo.track(eventWithCategory: .menuDrawer, name: "openByButton")
                                    navigationDrawerState.open()
                                } label: {
                                    Image(resource: MailResourcesAsset.burger)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: Constants.navbarIconSize, height: Constants.navbarIconSize)
                                }
                            }
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        if !multipleSelectionViewModel.isEnabled {
                            Text(splitViewManager.selectedFolder?.localizedName ?? "")
                                .textStyle(.header1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if multipleSelectionViewModel.isEnabled {
                            Button(MailResourcesStrings.Localizable.buttonSelectAll) {
                                selectAll()
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
                                isShowingSwitchAccount.toggle()
                            } label: {
                                splitViewManager.avatarImage
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
                                    ToolbarButton(
                                        text: action.shortTitle ?? action.title,
                                        icon: action.icon,
                                        width: reader.size.width / 5
                                    ) {
                                        Task {
                                            await tryOrDisplayError {
                                                try await multipleSelectionViewModel.didTap(
                                                    action: action,
                                                    flushAlert: $flushAlert
                                                )
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
        .sheet(isPresented: $isShowingSwitchAccount) {
            AccountView(mailboxes: AccountManager.instance.mailboxes)
        }
    }
}

struct ThreadListView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListView(
            mailboxManager: PreviewHelper.sampleMailboxManager,
            folder: PreviewHelper.sampleFolder,
            editedMessageDraft: .constant(nil),
            messageReply: .constant(nil),
            isCompact: false
        )
    }
}
