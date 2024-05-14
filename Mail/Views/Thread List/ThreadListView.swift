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
import MailCoreUI
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI
import SwiftUIIntrospect

struct ThreadListView: View {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var userActivityController: UserActivityController

    @EnvironmentObject private var mainViewState: MainViewState

    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor
    @AppStorage(UserDefaults.shared.key(.hasDismissedUpdateVersionView)) private var hasDismissedUpdateVersionView =
        DefaultPreferences
            .hasDismissedUpdateVersionView

    @State private var fetchingTask: Task<Void, Never>?
    @State private var isRefreshing = false
    @State private var firstLaunch = true
    @ModalState private var isShowingUpdateAlert = false
    @ModalState private var flushAlert: FlushAlertState?

    @StateObject var viewModel: ThreadListViewModel
    @StateObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel
    @StateObject private var scrollObserver = ScrollObserver()
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    private var shouldDisplayEmptyView: Bool {
        viewModel.isEmpty && viewModel.loadingPageTaskId == nil
    }

    private var shouldDisplayNoNetworkView: Bool {
        !networkMonitor.isConnected && viewModel.sections == nil
    }

    private var shouldDisplayHeaderCell: Bool {
        shouldDisplayFlushFolderView || shouldDisplayProgressView || shouldDisplayVerticalInsetView || shouldDisplayUpdateVersion
    }

    private var shouldDisplayFlushFolderView: Bool {
        !viewModel.isEmpty && (viewModel.frozenFolder.role == .trash || viewModel.frozenFolder.role == .spam)
    }

    private var shouldDisplayProgressView: Bool {
        viewModel.loadingPageTaskId != nil && !isRefreshing
    }

    private var shouldDisplayVerticalInsetView: Bool {
        threadDensity == .compact
    }

    private var shouldDisplayUpdateVersion: Bool {
        Constants.isUsingABreakableOSVersion && !hasDismissedUpdateVersionView && viewModel.frozenFolder.role == .inbox
    }

    init(mailboxManager: MailboxManager,
         frozenFolder: Folder,
         selectedThreadOwner: SelectedThreadOwnable) {
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(mailboxManager: mailboxManager,
                                                                   frozenFolder: frozenFolder,
                                                                   selectedThreadOwner: selectedThreadOwner))
        _multipleSelectionViewModel = StateObject(wrappedValue: ThreadListMultipleSelectionViewModel(frozenFolder: frozenFolder))

        UITableViewCell.appearance().focusEffect = .none
    }

    var body: some View {
        VStack(spacing: 0) {
            ThreadListHeader(isMultipleSelectionEnabled: multipleSelectionViewModel.isEnabled,
                             folder: viewModel.frozenFolder,
                             unreadFilterOn: $viewModel.filterUnreadOn)
                .id(viewModel.frozenFolder.id)

            ScrollViewReader { proxy in
                List {
                    if shouldDisplayHeaderCell {
                        VStack(spacing: 0) {
                            if shouldDisplayFlushFolderView {
                                FlushFolderView(
                                    folder: viewModel.frozenFolder,
                                    mailboxManager: viewModel.mailboxManager,
                                    flushAlert: $flushAlert
                                )
                            }

                            if shouldDisplayProgressView, let loadingPageTaskId = viewModel.loadingPageTaskId {
                                ProgressView()
                                    .id(loadingPageTaskId)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, value: .small)
                            }

                            if shouldDisplayVerticalInsetView {
                                ListVerticalInsetView(height: UIPadding.verySmall)
                            }

                            if shouldDisplayUpdateVersion {
                                UpdateVersionView(isShowingUpdateAlert: $isShowingUpdateAlert)
                            }
                        }
                        .threadListCellAppearance()
                    }

                    ForEach(viewModel.sections ?? []) { section in
                        Section {
                            ForEach(section.threads) { thread in
                                ThreadListCell(viewModel: viewModel,
                                               multipleSelectionViewModel: multipleSelectionViewModel,
                                               thread: thread,
                                               threadDensity: threadDensity,
                                               accentColor: accentColor,
                                               isSelected: mainViewState.selectedThread?.uid == thread.uid,
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

                    VStack(spacing: 0) {
                        if !viewModel.filterUnreadOn {
                            LoadMoreButton(currentFolder: viewModel.frozenFolder)
                        }

                        ListVerticalInsetView(height: multipleSelectionViewModel.isEnabled ? 100 : 110)
                    }
                    .threadListCellAppearance()
                }
                .listStyle(.plain)
                .observeScroll(with: scrollObserver)
                .emptyState(isEmpty: shouldDisplayEmptyView) {
                    switch viewModel.frozenFolder.role {
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
                              title: MailResourcesStrings.Localizable.buttonNewMessage,
                              isExtended: scrollObserver.scrollDirection != .bottom) {
            matomo.track(eventWithCategory: .newMessage, name: "openFromFab")
            mainViewState.composeMessageIntent = .new(originMailboxManager: viewModel.mailboxManager)
        }
        .shortcutModifier(viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
        .onAppear {
            networkMonitor.start()
            userActivityController.setCurrentActivity(mailbox: viewModel.mailboxManager.mailbox,
                                                      folder: mainViewState.selectedFolder)
        }
        .onChange(of: multipleSelectionViewModel.isEnabled) { isEnabled in
            scrollObserver.shouldObserve = !isEnabled
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
            FlushFolderAlertView(flushAlert: item, folder: viewModel.frozenFolder)
        }
        .customAlert(isPresented: $isShowingUpdateAlert) {
            UpdateVersionAlertView(onDismiss: {
                hasDismissedUpdateVersionView = true
            })
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

#Preview {
    ThreadListView(
        mailboxManager: PreviewHelper.sampleMailboxManager,
        frozenFolder: PreviewHelper.sampleFolder,
        selectedThreadOwner: PreviewHelper.mockSelectedThreadOwner
    )
}
