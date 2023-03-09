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

import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel

    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var globalBottomSheet: GlobalBottomSheet

    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity

    @StateObject var bottomSheet: ThreadBottomSheet

    @State public var isSearchFieldFocused = false
    @Binding private var editedMessageDraft: Draft?
    @Binding private var messageReply: MessageReply?

    let isCompact: Bool

    init(mailboxManager: MailboxManager,
         folder: Folder?,
         editedMessageDraft: Binding<Draft?>,
         messageReply: Binding<MessageReply?>,
         isCompact: Bool) {
        let threadBottomSheet = ThreadBottomSheet()
        _editedMessageDraft = editedMessageDraft
        _messageReply = messageReply
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
                                viewModel.searchFilter(filter)
                            }
                        }
                    }
                }
            }
            .padding(.top, 16)

            if viewModel.searchState == .noResults {
                SearchNoResultView()
            } else if viewModel.searchState == .noHistory {
                Text(MailResourcesStrings.Localizable.searchNoHistoryDescription)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 16)
                    .textStyle(.bodySmallSecondary)
            } else {
                List {
                    if viewModel.searchState == .history {
                        searchHistoryList(history: viewModel.searchHistory)
                    } else if viewModel.searchState == .results {
                        contactList(contacts: viewModel.contacts)
                        threadList(threads: viewModel.threads)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUiColor)
        .navigationBarSearchListStyle()
        .floatingPanel(state: bottomSheet, halfOpening: true) {
            if case let .actions(target) = bottomSheet.state, !target.isInvalidated {
                ActionsView(mailboxManager: viewModel.mailboxManager,
                            target: target,
                            state: bottomSheet,
                            globalSheet: globalBottomSheet) { message, replyMode in
                    messageReply = MessageReply(message: message, replyMode: replyMode)
                }
            }
        }
        .refreshable {
            await viewModel.fetchThreads()
        }
        .onDisappear {
            if viewModel.selectedThread == nil {
                viewModel.observationSearchThreadToken?.invalidate()
            }
        }
        .onAppear {
            if viewModel.selectedThread == nil {
                viewModel.initSearch()
            }
            viewModel.selectedThread = nil
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isCompact {
                    Button {
                        Constants.globallyResignFirstResponder()
                        splitViewManager.showSearch = false
                    } label: {
                        Image(resource: MailResourcesAsset.arrowLeft)
                    }
                }
            }

            ToolbarItem(placement: .navigation) {
                SearchTextField(value: $viewModel.searchValue, isFocused: $isSearchFieldFocused) {
                    viewModel.matomo.track(eventWithCategory: .search, name: "validateSearch")
                    viewModel.searchThreadsForCurrentValue()
                } onDelete: {
                    viewModel.matomo.track(eventWithCategory: .search, name: "deleteSearch")
                    viewModel.clearSearch()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .matomoView(view: ["SearchView"])
    }

    func threadList(threads: [Thread]) -> some View {
        Section {
            ForEach(threads) { thread in
                Group {
                    if thread.shouldPresentAsDraft {
                        Button(action: {
                            DraftUtils.editDraft(
                                from: thread,
                                mailboxManager: viewModel.mailboxManager,
                                editedMessageDraft: $editedMessageDraft
                            )
                        }, label: {
                            ThreadCell(thread: thread,
                                       mailboxManager: viewModel.mailboxManager,
                                       density: threadDensity)
                        })
                    } else {
                        ZStack {
                            NavigationLink(destination: {
                                ThreadView(
                                    mailboxManager: viewModel.mailboxManager,
                                    thread: thread
                                )
                                .onAppear {
                                    viewModel.selectedThread = thread
                                }
                            }, label: {
                                EmptyView()
                            })
                            .opacity(0)

                            ThreadCell(thread: thread,
                                       mailboxManager: viewModel.mailboxManager,
                                       density: threadDensity)
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .padding(.leading, -4)
                .onAppear {
                    viewModel.loadNextPageIfNeeded(currentItem: thread)
                }
            }
        } header: {
            if threadDensity != .compact && !threads.isEmpty {
                Text(MailResourcesStrings.Localizable.searchAllMessages)
                    .textStyle(.bodySmallSecondary)
            }
        } footer: {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .id(UUID())
            }
        }
        .listRowInsets(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
        .listRowSeparator(.hidden)
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
    }

    func contactList(contacts: [Recipient]) -> some View {
        Section {
            ForEach(contacts) { contact in
                RecipientAutocompletionCell(recipient: contact)
                    .onTapGesture {
                        viewModel.matomo.track(eventWithCategory: .search, name: "selectContact")
                        Constants.globallyResignFirstResponder()
                        viewModel.searchThreadsForContact(contact)
                    }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, threadDensity.cellVerticalPadding)
        } header: {
            if !contacts.isEmpty {
                Text(MailResourcesStrings.Localizable.contactsSearch)
                    .textStyle(.bodySmallSecondary)
            }
        }
        .listRowInsets(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
        .listRowSeparator(.hidden)
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
    }

    func searchHistoryList(history: SearchHistory) -> some View {
        Section {
            ForEach(history.history, id: \.self) { searchItem in
                HStack(spacing: 8) {
                    Text(searchItem)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        deleteSearchTapped(searchItem: searchItem)
                    } label: {
                        Image(resource: MailResourcesAsset.close)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.accentColor)
                            .frame(width: 17, height: 17)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.matomo.track(eventWithCategory: .search, name: "fromHistory")
                    Constants.globallyResignFirstResponder()
                    viewModel.searchValue = searchItem
                    Task {
                        await viewModel.fetchThreads()
                    }
                }
            }
            .padding(.horizontal, 4)
        } header: {
            Text(MailResourcesStrings.Localizable.recentSearchesTitle)
                .textStyle(.bodySmallSecondary)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
        .listRowInsets(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
    }

    private func deleteSearchTapped(searchItem: String) {
        viewModel.matomo.track(eventWithCategory: .search, name: "deleteFromHistory")
        Task {
            await tryOrDisplayError {
                viewModel.searchHistory = await viewModel.mailboxManager.delete(
                    searchHistory: viewModel.searchHistory,
                    with: searchItem
                )
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(mailboxManager: PreviewHelper.sampleMailboxManager,
                   folder: PreviewHelper.sampleFolder,
                   editedMessageDraft: .constant(nil),
                   messageReply: .constant(nil),
                   isCompact: true)
    }
}
