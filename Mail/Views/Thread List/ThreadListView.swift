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

final class FlushAlertState: Identifiable {
    let id = UUID()
    let deletedMessages: Int?
    let completion: () async -> Void

    init(deletedMessages: Int? = nil, completion: @escaping () async -> Void) {
        self.deletedMessages = deletedMessages
        self.completion = completion
    }
}

struct ThreadListView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var navigationState: NavigationState

    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @State private var newPresentedDraft: Draft?
    @State private var fetchingTask: Task<Void, Never>?
    @State private var isRefreshing = false
    @State private var firstLaunch = true
    @State private var flushAlert: FlushAlertState?
    @State private var isLoadingMore = false

    @StateObject var viewModel: ThreadListViewModel
    @StateObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel
    @StateObject private var networkMonitor = NetworkMonitor()

    private var shouldDisplayEmptyView: Bool {
        viewModel.folder.lastUpdate != nil && viewModel.sections.isEmpty && !viewModel.isLoadingPage
    }

    private var shouldDisplayNoNetworkView: Bool {
        !networkMonitor.isConnected && viewModel.folder.lastUpdate == nil
    }

    private var displayLoadMoreButton: Bool {
        return !viewModel.folder.isHistoryComplete && !viewModel.sections.isEmpty
    }

    init(mailboxManager: MailboxManager,
         folder: Folder,
         isCompact: Bool) {
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(mailboxManager: mailboxManager,
                                                                   folder: folder,
                                                                   isCompact: isCompact))
        _multipleSelectionViewModel =
            StateObject(wrappedValue: ThreadListMultipleSelectionViewModel(mailboxManager: mailboxManager))

        UITableViewCell.appearance().focusEffect = .none
    }

    var body: some View {
        VStack(spacing: 0) {
            ThreadListHeader(isMultipleSelectionEnabled: multipleSelectionViewModel.isEnabled,
                             isConnected: networkMonitor.isConnected,
                             lastUpdate: viewModel.lastUpdate,
                             unreadCount: splitViewManager.selectedFolder?.unreadCount ?? 0,
                             unreadFilterOn: $viewModel.filterUnreadOn)

            ScrollViewReader { proxy in
                List {
                    if !viewModel.sections.isEmpty,
                       viewModel.folder.role == .trash || viewModel.folder.role == .spam {
                        FlushFolderView(
                            folder: viewModel.folder,
                            mailboxManager: viewModel.mailboxManager,
                            flushAlert: $flushAlert
                        )
                        .threadListCellAppearance()
                    }

                    if viewModel.isLoadingPage && !isRefreshing {
                        ProgressView()
                            .id(UUID())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, UIConstants.progressItemsVerticalPadding)
                            .threadListCellAppearance()
                    }

                    if threadDensity == .compact {
                        ListVerticalInsetView(height: 4)
                    }

                    ForEach(viewModel.sections) { section in
                        Section {
                            ForEach(section.threads) { thread in
                                ThreadListCell(viewModel: viewModel,
                                               multipleSelectionViewModel: multipleSelectionViewModel,
                                               thread: thread,
                                               threadDensity: threadDensity,
                                               isSelected: viewModel.selectedThread?.uid == thread.uid,
                                               isMultiSelected: multipleSelectionViewModel.selectedItems
                                                   .contains { $0.id == thread.id })
                            }
                        } header: {
                            if threadDensity != .compact {
                                Text(section.title)
                                    .textStyle(.bodySmallSecondary)
                            }
                        }
                    }

                    Group {
                        if isLoadingMore {
                            ProgressView()
                                .id(UUID())
                                .frame(maxWidth: .infinity)
                        } else if displayLoadMoreButton && !viewModel.filterUnreadOn {
                            MailButton(label: MailResourcesStrings.Localizable.buttonLoadMore) {
                                withAnimation {
                                    isLoadingMore = true
                                }
                                Task {
                                    await tryOrDisplayError {
                                        _ = try await viewModel.mailboxManager.fetchOnePage(
                                            folder: viewModel.folder.freeze(),
                                            direction: .previous
                                        )
                                        isLoadingMore = false
                                    }
                                }
                            }
                            .mailButtonStyle(.smallLink)
                            .frame(alignment: .leading)
                        }
                    }
                    .padding(.vertical, UIConstants.progressItemsVerticalPadding)

                    ListVerticalInsetView(height: multipleSelectionViewModel.isEnabled ? 100 : 110)
                }
                .environment(\.defaultMinListRowHeight, 4)
                .emptyState(isEmpty: shouldDisplayEmptyView) {
                    switch viewModel.folder.role {
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
        .threadListToolbar(flushAlert: $flushAlert,
                           viewModel: viewModel,
                           multipleSelectionViewModel: multipleSelectionViewModel) {
            withAnimation(.default.speed(2)) {
                multipleSelectionViewModel.selectAll(threads: viewModel.filteredThreads)
            }
        }
        .floatingActionButton(isEnabled: !multipleSelectionViewModel.isEnabled,
                              icon: MailResourcesAsset.pencilPlain,
                              title: MailResourcesStrings.Localizable.buttonNewMessage) {
            matomo.track(eventWithCategory: .newMessage, name: "openFromFab")

            // Instantiate a new Draft will open the editor.
            newPresentedDraft = Draft(localUUID: UUID().uuidString)
        }
        .onAppear {
            networkMonitor.start()
            if viewModel.isCompact {
                viewModel.selectedThread = nil
            }
        }
        .onChange(of: splitViewManager.selectedFolder) { newFolder in
            changeFolder(newFolder: newFolder)
        }
        .onChange(of: viewModel.selectedThread) { newThread in
            if let newThread {
                navigationState.threadPath = [newThread]
            } else {
                navigationState.threadPath = []
            }
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
        .sheet(item: $newPresentedDraft) { newDraft in
            ComposeMessageView.newMessage(newDraft, mailboxManager: viewModel.mailboxManager)
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
            await viewModel.mailboxManager.cancelRefresh()

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

struct ThreadListView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListView(
            mailboxManager: PreviewHelper.sampleMailboxManager,
            folder: PreviewHelper.sampleFolder,
            isCompact: false
        )
    }
}
