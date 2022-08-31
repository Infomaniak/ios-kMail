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

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel

    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var menuSheet: MenuSheet
    @EnvironmentObject var globalBottomSheet: GlobalBottomSheet

    @AppStorage(UserDefaults.shared.key(.threadDensity)) var threadDensity = ThreadDensity.normal

    @StateObject var bottomSheet: ThreadBottomSheet
    @State private var navigationController: UINavigationController?

    @State public var isSearchFieldFocused = false

    let isCompact: Bool

    init(mailboxManager: MailboxManager, folder: Folder?, isCompact: Bool) {
        let threadBottomSheet = ThreadBottomSheet()
        _bottomSheet = StateObject(wrappedValue: threadBottomSheet)
        _viewModel = StateObject(wrappedValue: SearchViewModel(mailboxManager: mailboxManager, folder: folder))
        self.isCompact = isCompact
    }

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(viewModel.filters) { filter in
                        if filter == .folder {
                            SearchFilterFolderCell(selection: $viewModel.selectedSearchFolderId, folders: viewModel.folderList)
                                .padding(.horizontal, 12)
                        } else {
                            SearchFilterCell(
                                title: filter.title,
                                isSelected: viewModel.selectedFilters.contains(filter)
                            )
                            .padding(.vertical, 2)
                            .padding(.trailing, 0)
                            .padding(.leading, 12)
                            .onTapGesture {
                                viewModel.updateSelection(filter: filter)
                            }
                        }
                    }
                }
            }
            .padding(.top, 16)

            List {
                if viewModel.showHistory {
                    searchHistoryList(history: viewModel.searchHistory)
                } else {
                    if !viewModel.contacts.isEmpty && isSearchFieldFocused {
                        contactList(contacts: viewModel.contacts)
                    }

                    if !viewModel.threads.isEmpty {
                        threadList(threads: viewModel.threads)
                    } else if viewModel.searchInfo.hasSearched {
                        // TODO: - Add no result view
                        EmptyView()
                    }

                    if viewModel.searchInfo.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(MailResourcesAsset.backgroundColor.swiftUiColor)
        .introspectNavigationController { navigationController in
            let newNavController = navigationController
            // Style toolbar
            let appereance = UIToolbarAppearance()
            appereance.configureWithOpaqueBackground()
            appereance.backgroundColor = MailResourcesAsset.backgroundToolbarColor.color
            appereance.shadowColor = .clear
            UIToolbar.appearance().standardAppearance = appereance
            UIToolbar.appearance().scrollEdgeAppearance = appereance
            newNavController.toolbar.barTintColor = .white
            newNavController.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
            // Style navigation bar
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            newNavController.navigationBar.standardAppearance = appearance
            newNavController.navigationBar.scrollEdgeAppearance = nil
            self.navigationController = newNavController
        }
        .floatingPanel(state: bottomSheet) {
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
        .refreshable {
            await viewModel.fetchThreads()
        }
        .onDisappear {
            if viewModel.selectedThread == nil {
                viewModel.observeSearch = false
            }
        }
        .onAppear {
            if viewModel.selectedThread == nil {
                viewModel.initSearch()
            }
            viewModel.selectedThread = nil

            MatomoUtils.track(view: ["SearchView"])
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if isCompact {
                    Button {
                        Constants.globallyResignFirstResponder()
                        splitViewManager.showSearch = false
                    } label: {
                        Image(resource: MailResourcesAsset.arrowLeft)
                    }
                } else {
                    EmptyView()
                }
            }

            ToolbarItem(placement: .principal) {
                SearchTextField(value: $viewModel.searchValue, isFocused: $isSearchFieldFocused) {
                    Task {
                        await viewModel.fetchThreads()
                    }
                } onDelete: {
                    viewModel.clearSearchValue()
                }
            }
        }
    }

    func threadList(threads: [Thread]) -> some View {
        Section {
            ForEach(threads) { thread in
                Group {
                    if viewModel.lastSearchFolderId == viewModel.mailboxManager.getFolder(with: .draft)?._id {
                        Button(action: {
                            DraftUtils.editDraft(from: thread, mailboxManager: viewModel.mailboxManager, menuSheet: menuSheet)
                        }, label: {
                            ThreadListCell(mailboxManager: viewModel.mailboxManager, thread: thread)
                        })
                    } else {
                        ZStack {
                            NavigationLink(destination: {
                                ThreadView(
                                    mailboxManager: viewModel.mailboxManager,
                                    thread: thread,
                                    folderId: viewModel.lastSearchFolderId,
                                    navigationController: navigationController
                                )
                                .onAppear {
                                    viewModel.selectedThread = thread
                                }
                            }, label: {
                                EmptyView()
                            })
                            .opacity(0)

                            ThreadListCell(mailboxManager: viewModel.mailboxManager, thread: thread)
                        }
                    }
                }
                .onAppear {
                    viewModel.loadNextPageIfNeeded(currentItem: thread)
                }
            }
        } header: {
            if threadDensity != .compact {
                Text(MailResourcesStrings.Localizable.searchAllMessages)
                    .textStyle(.calloutSecondary)
            }
        }
        .listRowInsets(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
        .listRowSeparator(.hidden)
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
    }

    func contactList(contacts: [Recipient]) -> some View {
        Section {
            ForEach(contacts, id: \.email) { contact in
                RecipientAutocompletionCell(recipient: contact)
                    .onTapGesture {
                        viewModel.searchValue = "\"" + contact.email + "\""
                        viewModel.searchValueType = .contact
                        Task {
                            await viewModel.fetchThreads()
                        }
                    }
            }
            .padding(.horizontal, 4)
        } header: {
            Text(MailResourcesStrings.Localizable.contactsSearch)
                .textStyle(.calloutSecondary)
        }
        .listRowInsets(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
        .listRowSeparator(.hidden)
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
    }

    func searchHistoryList(history: SearchHistory) -> some View {
        Section {
            ForEach(history.history, id: \.self) { searchItem in
                Text(searchItem)
                    .onTapGesture {
                        viewModel.searchValue = searchItem
                        Task {
                            await viewModel.fetchThreads()
                        }
                    }
            }
            .padding(.horizontal, 4)
        } header: {
            Text(MailResourcesStrings.Localizable.recentSearchesTitle)
                .textStyle(.calloutSecondary)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
        .listRowInsets(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(mailboxManager: PreviewHelper.sampleMailboxManager, folder: PreviewHelper.sampleFolder, isCompact: true)
    }
}
