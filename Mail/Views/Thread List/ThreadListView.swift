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

struct ThreadListView: View {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var userActivityController: UserActivityController

    @EnvironmentObject private var mainViewState: MainViewState

    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @State private var fetchingTask: Task<Void, Never>?
    @State private var isRefreshing = false
    @State private var firstLaunch = true
    @State private var flushAlert: FlushAlertState?

    @StateObject var viewModel: ThreadListViewModel
    @StateObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    private var shouldDisplayEmptyView: Bool {
        viewModel.isEmpty && !viewModel.isLoadingPage
    }

    private var shouldDisplayNoNetworkView: Bool {
        !networkMonitor.isConnected && viewModel.sections == nil
    }

    init(mailboxManager: MailboxManager,
         folder: Folder,
         isCompact: Bool) {
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(mailboxManager: mailboxManager,
                                                                   folder: folder,
                                                                   isCompact: isCompact))
        _multipleSelectionViewModel = StateObject(wrappedValue: ThreadListMultipleSelectionViewModel())

        UITableViewCell.appearance().focusEffect = .none
    }

    var body: some View {
        VStack(spacing: 0) {
            ThreadListHeader(isMultipleSelectionEnabled: multipleSelectionViewModel.isEnabled,
                             folder: viewModel.folder,
                             unreadFilterOn: $viewModel.filterUnreadOn)
                .id(viewModel.folder.id)

            ScrollViewReader { proxy in
                List {
                    if !viewModel.isEmpty,
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
                            .padding(.vertical, value: .small)
                            .threadListCellAppearance()
                    }

                    if threadDensity == .compact {
                        ListVerticalInsetView(height: UIPadding.verySmall)
                    }

                    ForEach(viewModel.sections ?? []) { section in
                        Section {
                            ForEach(section.threads) { thread in
                                ThreadListCell(viewModel: viewModel,
                                               multipleSelectionViewModel: multipleSelectionViewModel,
                                               thread: thread,
                                               threadDensity: threadDensity,
                                               isSelected: viewModel.selectedThread?.uid == thread.uid,
                                               isMultiSelected: multipleSelectionViewModel.selectedItems.contains(thread),
                                               flushAlert: $flushAlert)
                            }
                        } header: {
                            if threadDensity != .compact {
                                Text(section.title)
                                    .textStyle(.bodySmallSecondary)
                            }
                        }
                    }

                    LoadMoreButton(currentFolder: viewModel.folder)

                    ListVerticalInsetView(height: multipleSelectionViewModel.isEnabled ? 100 : 110)
                }
                .plainList()
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
                           multipleSelectionViewModel: multipleSelectionViewModel)
        .floatingActionButton(isEnabled: !multipleSelectionViewModel.isEnabled,
                              icon: MailResourcesAsset.pencilPlain,
                              title: MailResourcesStrings.Localizable.buttonNewMessage) {
            matomo.track(eventWithCategory: .newMessage, name: "openFromFab")
            mainViewState.editedDraft = EditedDraft.new()
        }
        .shortcutModifier(viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
        .onAppear {
            networkMonitor.start()
            if viewModel.isCompact {
                viewModel.selectedThread = nil
            }
            userActivityController.setCurrentActivity(mailbox: viewModel.mailboxManager.mailbox,
                                                      folder: mainViewState.selectedFolder)
        }
        .onChange(of: viewModel.selectedThread) { newThread in
            if let newThread {
                mainViewState.threadPath = [newThread]
            } else {
                mainViewState.threadPath = []
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
        .customAlert(item: $flushAlert) { item in
            FlushFolderAlertView(flushAlert: item, folder: viewModel.folder)
        }
        .matomoView(view: [MatomoUtils.View.threadListView.displayName, "Main"])
    }

    private func updateFetchingTask() {
        guard fetchingTask == nil else { return }
        fetchingTask = Task {
            await viewModel.fetchThreads()
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
