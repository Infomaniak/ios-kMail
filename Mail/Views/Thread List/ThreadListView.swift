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
    @ObservedSectionedResults(Thread.self, sectionKeyPath: \.sectionDate) var sectionedThreads
    @ObservedResults(Thread.self) var threads
    @ObservedRealmObject var currentFolder: Folder
    @State private var isFilteringUnread = false

    @LazyInjectService private var matomo: MatomoUtils

    let isCompact: Bool

    private var shouldDisplayEmptyView: Bool {
        currentFolder.lastUpdate != nil && sectionedThreads.isEmpty && !viewModel.isLoadingPage
    }

    private var shouldDisplayNoNetworkView: Bool {
        !networkMonitor.isConnected && currentFolder.lastUpdate == nil
    }

    init(mailboxManager: MailboxManager,
         folder: Folder,
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
                                                                   moveSheet: moveEmailSheet))
        _multipleSelectionViewModel =
            StateObject(wrappedValue: ThreadListMultipleSelectionViewModel(mailboxManager: mailboxManager))
        self.isCompact = isCompact

        _sectionedThreads = ObservedSectionedResults(
            Thread.self,
            sectionKeyPath: \.sectionDate,
            sortDescriptors: [SortDescriptor(keyPath: "date", ascending: false)],
            where: { $0.folders.contains(folder) },
            configuration: mailboxManager.realmConfiguration
        )

        _threads = ObservedResults(Thread.self, configuration: mailboxManager.realmConfiguration) { $0.folders.contains(folder) }

        _currentFolder = ObservedRealmObject(wrappedValue: folder)

        UITableViewCell.appearance().focusEffect = .none
    }

    var body: some View {
        VStack(spacing: 0) {
            ThreadListHeader(isMultipleSelectionEnabled: multipleSelectionViewModel.isEnabled,
                             isConnected: networkMonitor.isConnected,
                             lastUpdate: currentFolder.lastUpdate,
                             unreadCount: splitViewManager.selectedFolder?.unreadCount ?? 0,
                             unreadFilterOn: $isFilteringUnread)

            List {
                if viewModel.isLoadingPage && !isRefreshing {
                    ProgressView()
                        .id(UUID())
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                }

                if !sectionedThreads.isEmpty,
                   currentFolder.role == .trash || currentFolder.role == .spam {
                    FlushFolderView(folder: currentFolder, mailboxManager: viewModel.mailboxManager, flushAlert: $flushAlert)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init())
                }

                if threadDensity == .compact {
                    ListVerticalInsetView(height: 4)
                }

                ForEach(sectionedThreads) { section in
                    Section {
                        ForEach(section) { thread in
                            ThreadListCell(thread: thread,
                                           viewModel: viewModel,
                                           multipleSelectionViewModel: multipleSelectionViewModel,
                                           threadDensity: threadDensity,
                                           isSelected: multipleSelectionViewModel.selectedItems
                                               .contains { $0.id == thread.id },
                                           editedMessageDraft: $editedMessageDraft)
                                .id(thread.id)
                        }
                    } header: {
                        if threadDensity != .compact {
                            Text(Thread.ReferenceDate.titleFromRawSectionKey(section.key))
                                .textStyle(.bodySmallSecondary)
                        }
                    }
                }

                ListVerticalInsetView(height: multipleSelectionViewModel.isEnabled ? 100 : 110)
            }
            .environment(\.defaultMinListRowHeight, 4)
            .emptyState(isEmpty: shouldDisplayEmptyView) {
                switch currentFolder.role {
                case .inbox:
                    EmptyStateView.emptyInbox
                case .trash:
                    EmptyStateView.emptyTrash
                default:
                    EmptyStateView.emptyFolder
                }
            }
            .emptyState(isEmpty: shouldDisplayNoNetworkView) {
                EmptyStateView.noNetwork
            }
            .background(MailResourcesAsset.backgroundColor.swiftUIColor)
            .listStyle(.plain)
            .appShadow()
        }
        .onChange(of: isFilteringUnread) { newValue in
            withAnimation {
                if newValue {
                    _sectionedThreads.where = { $0.folders.contains(currentFolder) && $0.unseenMessages > 0 }
                    _threads.where = { $0.folders.contains(currentFolder) && $0.unseenMessages > 0 }
                } else {
                    _sectionedThreads.where = { $0.folders.contains(currentFolder) }
                    _threads.where = { $0.folders.contains(currentFolder) }
                }
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
                                    threads: threads,
                                    multipleSelectionViewModel: multipleSelectionViewModel,
                                    selectAll: {
                                        withAnimation(.default.speed(2)) {
                                            multipleSelectionViewModel.selectAll(threads: threads)
                                        }
                                    }))
        .floatingActionButton(isEnabled: !multipleSelectionViewModel.isEnabled,
                              icon: MailResourcesAsset.pencilPlain,
                              title: MailResourcesStrings.Localizable.buttonNewMessage) {
            matomo.track(eventWithCategory: .newMessage, name: "openFromFab")
            isShowingComposeNewMessageView.toggle()
        }
        .floatingPanel(state: bottomSheet, halfOpening: true) {
            if case .actions(let target) = bottomSheet.state, !target.isInvalidated {
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
            if firstLaunch {
                updateFetchingTask()
                firstLaunch = false
            }
        }
        .sheet(isPresented: $isShowingComposeNewMessageView) {
            ComposeMessageView.newMessage(mailboxManager: viewModel.mailboxManager)
        }
        .sheet(isPresented: $moveSheet.isShowing) {
            if case .move(let folderId, let handler) = moveSheet.state {
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
    let threads: Results<Thread>
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
                                matomo.track(eventWithCategory: .multiSelection, name: "cancel")
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
                                    MailResourcesAsset.burger.swiftUIImage
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
                            Button(multipleSelectionViewModel.selectedItems.count == threads.count
                                ? MailResourcesStrings.Localizable.buttonUnselectAll
                                : MailResourcesStrings.Localizable.buttonSelectAll) {
                                    selectAll()
                                }
                                .animation(nil, value: multipleSelectionViewModel.selectedItems)
                        } else {
                            Button {
                                splitViewManager.showSearch = true
                            } label: {
                                MailResourcesAsset.search.swiftUIImage
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: Constants.navbarIconSize, height: Constants.navbarIconSize)
                            }

                            Button {
                                isShowingSwitchAccount.toggle()
                            } label: {
                                AvatarView(avatarDisplayable: AccountManager.instance.currentAccount.user)
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
                                    .disabled(action == .archive && splitViewManager.selectedFolder?.role == .archive)
                                }

                                ToolbarButton(text: MailResourcesStrings.Localizable.buttonMore,
                                              icon: MailResourcesAsset.plusActions.swiftUIImage,
                                              width: reader.size.width / 5) {
                                    bottomSheet
                                        .open(state: .actions(.threads(Array(multipleSelectionViewModel.selectedItems), true)))
                                }
                            }
                            .disabled(multipleSelectionViewModel.selectedItems.isEmpty)
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
