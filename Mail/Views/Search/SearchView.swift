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
import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel

    @EnvironmentObject var menuSheet: MenuSheet
    @EnvironmentObject var globalBottomSheet: GlobalBottomSheet

    @AppStorage(UserDefaults.shared.key(.threadDensity)) var threadDensity = ThreadDensity.normal

    @StateObject var bottomSheet: ThreadBottomSheet
    @State private var navigationController: UINavigationController?

    private let bottomSheetOptions = Constants.bottomSheetOptions + [.appleScrollBehavior]

    init(viewModel: SearchViewModel) {
        let threadBottomSheet = ThreadBottomSheet()
        _bottomSheet = StateObject(wrappedValue: threadBottomSheet)
        self.viewModel = viewModel

        print("token: \(AccountManager.instance.currentAccount.token.accessToken)")
    }

    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(viewModel.filters) { filter in
                        SearchFilterCell(title: filter.title, isSelected: viewModel.selectedFilters.contains(filter))
                            .padding(.vertical, 2)
                            .onTapGesture {
                                viewModel.updateSelection(filter: filter)
                            }
                    }
                }
            }

            if viewModel.threads.isEmpty {
                Spacer()
            } else {
                List {
                    Section {
                        threadList(threads: viewModel.threads)
                    } header: {
                        if !viewModel.threads.isEmpty && threadDensity != .compact {
                            // TODO: - Fix trad
                            Text("Tous les messages")
                                .textStyle(.calloutSecondary)
                        }
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
                .listStyle(.plain)
            }
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
//        .onAppear {
//            if isCompact {
//                selectedThread = nil
//            }
//            networkMonitor.start()
//            viewModel.globalBottomSheet = globalBottomSheet
//        }
//        .onChange(of: currentFolder) { newFolder in
//            guard let folder = newFolder else { return }
//            selectedThread = nil
//            viewModel.updateThreads(with: folder)
//        }
        .refreshable {
            await viewModel.fetchThreads()
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
            ToolbarItem {
                TextField("SearchField", text: $viewModel.searchValue)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onSubmit {
                        Task {
                            await viewModel.fetchThreads()
                        }
                    }
            }
        }
    }

    func threadList(threads: [Thread]) -> some View {
        ForEach(threads) { thread in
            Group {
//                if currentFolder?.role == .draft {
//                    Button(action: {
//                        editDraft(from: thread)
//                    }, label: {
//                        ThreadListCell(mailboxManager: viewModel.mailboxManager, thread: thread)
//                    })
//                } else {
                NavigationLink(destination: {
                    ThreadView(
                        mailboxManager: viewModel.mailboxManager,
                        thread: thread,
                        navigationController: navigationController
                    )
                    .onAppear { /* selectedThread = thread */ }
                }, label: {
                    ThreadListCell(mailboxManager: viewModel.mailboxManager, thread: thread)
                })
//                }
            }
            .listRowInsets(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
            .listRowSeparator(.hidden)
            .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
            .onAppear {
//                viewModel.loadNextPageIfNeeded(currentItem: thread)
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(viewModel: SearchViewModel(folder: nil))
    }
}
