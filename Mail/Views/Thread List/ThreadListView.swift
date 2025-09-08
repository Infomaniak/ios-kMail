/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI
import SwiftUIIntrospect
import VersionChecker

struct ThreadListView: View {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var userActivityController: UserActivityController
    @InjectService private var platformDetector: PlatformDetectable

    @EnvironmentObject private var mainViewState: MainViewState

    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor
    @AppStorage(UserDefaults.shared.key(.hasDismissedUpdateVersionView)) private var hasDismissedUpdateVersionView =
        DefaultPreferences.hasDismissedUpdateVersionView
    @AppStorage(UserDefaults.shared.key(.hasDismissedMacDisclaimerView)) private var hasDismissedMacDisclaimerView =
        DefaultPreferences.hasDismissedMacDisclaimerView

    @State private var fetchingTask: Task<Void, Never>?
    @State private var isRefreshing = false
    @ModalState private var isShowingUpdateAlert = false

    @StateObject private var viewModel: ThreadListViewModel
    @StateObject private var multipleSelectionViewModel: MultipleSelectionViewModel
    @StateObject private var scrollObserver = ScrollObserver()
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    private var shouldDisplayEmptyView: Bool {
        viewModel.isEmpty && viewModel.loadingPageTaskId == nil
    }

    private var shouldDisplayNoNetworkView: Bool {
        !networkMonitor.isConnected && viewModel.sections == nil
    }

    private var selection: Binding<Thread?>? {
        if #available(iOS 16.4, *) {
            return Binding(get: {
                mainViewState.selectedThread
            }, set: { newValue in
                guard !multipleSelectionViewModel.isEnabled else { return }
                mainViewState.selectedThread = newValue
            })
        } else {
            return nil
        }
    }

    init(mailboxManager: MailboxManager,
         frozenFolder: Folder,
         selectedThreadOwner: SelectedThreadOwnable) {
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(mailboxManager: mailboxManager,
                                                                   frozenFolder: frozenFolder,
                                                                   selectedThreadOwner: selectedThreadOwner))
        _multipleSelectionViewModel =
            StateObject(wrappedValue: MultipleSelectionViewModel(fromArchiveFolder: frozenFolder.role == .archive))

        UITableViewCell.appearance().focusEffect = .none
        UICollectionViewCell.appearance().focusEffect = .none
    }

    var body: some View {
        VStack(spacing: 0) {
            if #unavailable(iOS 26.0) {
                ThreadListHeader(isMultipleSelectionEnabled: multipleSelectionViewModel.isEnabled,
                                 folder: viewModel.frozenFolder,
                                 unreadFilterOn: $viewModel.filterUnreadOn,
                                 isRefreshing: viewModel.loadingPageTaskId != nil)
                .id(viewModel.frozenFolder.id)
            }

            QuotasAlertView(mailbox: viewModel.mailboxManager.mailbox)

            ScrollViewReader { proxy in
                List(selection: selection) {
                    if !viewModel.isEmpty,
                       viewModel.frozenFolder.role == .trash || viewModel.frozenFolder.role == .spam {
                        FlushFolderView(
                            folder: viewModel.frozenFolder,
                            mailboxManager: viewModel.mailboxManager,
                            destructiveAlert: $mainViewState.destructiveAlert
                        )
                        .threadListCellAppearance()
                    }

                    if threadDensity == .compact {
                        ListVerticalInsetView(height: IKPadding.micro)
                    }

                    if Constants.isUsingABreakableOSVersion && !hasDismissedUpdateVersionView && viewModel.frozenFolder
                        .role == .inbox {
                        MailUpdateVersionView(isShowingUpdateAlert: $isShowingUpdateAlert)
                            .threadListCellAppearance()
                    }

                    if platformDetector.isMac && !hasDismissedMacDisclaimerView {
                        MacUsageDisclaimerView(hasDismissedMacDisclaimerView: $hasDismissedMacDisclaimerView)
                            .threadListCellAppearance()
                    }

                    ForEach(viewModel.sections ?? []) { section in
                        Section {
                            ForEach(section.threads) { thread in
                                // ZStack is needed for lazy ForEach on iOS 18
                                ZStack {
                                    ThreadListCell(viewModel: viewModel,
                                                   multipleSelectionViewModel: multipleSelectionViewModel,
                                                   thread: thread,
                                                   threadDensity: threadDensity,
                                                   accentColor: accentColor,
                                                   isSelected: mainViewState.selectedThread?.uid == thread.uid,
                                                   isMultiSelected: multipleSelectionViewModel.selectedItems[thread.uid] != nil)
                                        .draggableThread(multipleSelectionViewModel.selectedItems.isEmpty ?
                                            [thread.uid] : Array(multipleSelectionViewModel.selectedItems.keys),
                                            enabled: thread.isMovable) {
                                                multipleSelectionViewModel.disable()
                                        }
                                }
                                .threadListCellAppearance()
                                .tag(thread)
                            }
                        } header: {
                            if threadDensity != .compact {
                                Text(section.title)
                                    .textStyle(.bodySmallSecondary)
                            }
                        }
                    }

                    if !viewModel.filterUnreadOn {
                        LoadMoreButton(currentFolder: viewModel.frozenFolder)
                    }

                    ListVerticalInsetView(height: multipleSelectionViewModel.isEnabled ? 100 : 110)
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
        .threadListToolbar(viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
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
        // swiftlint:disable:next trailing_closure
        .sceneLifecycle(willEnterForeground: {
            updateFetchingTask()
        })
        .task(id: viewModel.mailboxManager.mailbox.id) {
            updateFetchingTask()
        }
        .mailCustomAlert(item: $mainViewState.destructiveAlert) { item in
            DestructiveActionAlertView(destructiveAlert: item)
        }
        .mailCustomAlert(isPresented: $isShowingUpdateAlert) {
            // swiftlint:disable:next trailing_closure
            UpdateVersionAlertView(onDismiss: {
                hasDismissedUpdateVersionView = true
            })
        }
        .mailCustomAlert(item: $mainViewState.modifiedScheduleDraftResource) { container in
            ModifyMessageScheduleAlertView(draftResource: container.draftResource)
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
