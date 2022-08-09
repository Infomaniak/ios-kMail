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
    @ObservedObject var viewModel: SearchViewModel

    @EnvironmentObject var menuSheet: MenuSheet
    @EnvironmentObject var globalBottomSheet: GlobalBottomSheet

    @AppStorage(UserDefaults.shared.key(.threadDensity)) var threadDensity = ThreadDensity.normal

    @StateObject var bottomSheet: ThreadBottomSheet
    @State private var navigationController: UINavigationController?

    private let bottomSheetOptions = Constants.bottomSheetOptions + [.appleScrollBehavior]

    init(viewModel: SearchViewModel/*, observeThread: Binding<Bool>*/) {
        let threadBottomSheet = ThreadBottomSheet()
        _bottomSheet = StateObject(wrappedValue: threadBottomSheet)
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(viewModel.filters) { filter in
                        if filter == .folder {
                            SearchFilterFolderCell(selection: $viewModel.selectedSearchFolderId)
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
            .padding(.top, 32)

            List {
                if viewModel.threads.isEmpty && viewModel.contacts.isEmpty {
                    if !viewModel.searchHistory.history.isEmpty {
                        searchHistoryList(history: viewModel.searchHistory)
                    }
                } else {
                    if !viewModel.contacts.isEmpty {
                        contactList(contacts: viewModel.contacts)
                    }

                    if !viewModel.threads.isEmpty {
                        threadList(threads: viewModel.threads)
                    }

                    if viewModel.isLoadingPage {
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

            Spacer()
        }
        .navigationBarAppStyle()
        .introspectNavigationController { navigationController in
            self.navigationController = navigationController
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
        .refreshable {
            await viewModel.fetchThreads()
        }
        .onDisappear {
            // TODO: - Manage observer
//            viewModel.observeSearch = false
//            observeThread = true
        }
        .onAppear {
            MatomoUtils.track(view: ["SearchView"])
            // Style toolbar
            let appereance = UIToolbarAppearance()
            appereance.configureWithOpaqueBackground()
            appereance.backgroundColor = MailResourcesAsset.backgroundToolbarColor.color
            appereance.shadowColor = .clear
            UIToolbar.appearance().standardAppearance = appereance
            UIToolbar.appearance().scrollEdgeAppearance = appereance
            navigationController?.toolbar.barTintColor = .white
            navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
            // Style navigation bar
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = nil
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                SearchTextField(value: $viewModel.searchValue) {
                    Task {
                        await viewModel.fetchThreads()
                    }
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
                            editDraft(from: thread)
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
                        viewModel.searchValue = contact.email
                        viewModel.searchValueType = .contact
                        Task {
                            await viewModel.fetchThreads()
                        }
                    }
            }
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
        } header: {
            Text(MailResourcesStrings.Localizable.recentSearchesTitle)
                .textStyle(.calloutSecondary)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
        .listRowInsets(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
    }

    private func editDraft(from thread: Thread) {
        guard let message = thread.messages.first else { return }
        var sheetPresented = false

        // If we already have the draft locally, present it directly
        if let draft = viewModel.mailboxManager.draft(messageUid: message.uid)?.detached() {
            menuSheet.state = .editMessage(draft: draft)
            sheetPresented = true
        }

        // Update the draft
        Task { [sheetPresented] in
            let draft = try await viewModel.mailboxManager.draft(from: message)
            if !sheetPresented {
                menuSheet.state = .editMessage(draft: draft)
            }
        }
    }
}

// struct SearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        SearchView(viewModel: SearchViewModel(folder: nil))
//    }
// }
