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

import BottomSheet
import Introspect
import MailCore
import MailResources
import RealmSwift
import SwiftUI

class MenuSheet: SheetState<MenuSheet.State> {
    enum State: Equatable {
        case newMessage
        case editMessage(draft: Draft)
        case addAccount
    }
}

class ThreadBottomSheet: BottomSheetState<ThreadBottomSheet.State, ThreadBottomSheet.Position> {
    enum State: Equatable {
        case actions(ActionsTarget)
    }

    public enum Position: CGFloat, CaseIterable {
        case top = 0.975, middle = 0.4, hidden = 0
    }
}

struct ThreadListView: View {
    @StateObject var viewModel: ThreadListViewModel

    @EnvironmentObject var menuSheet: MenuSheet
    @EnvironmentObject var settingsSheet: SettingsSheet

    @Binding var currentFolder: Folder?

    @State private var avatarImage = Image(resource: MailResourcesAsset.placeholderAvatar)
    @State private var selectedThread: Thread?
    @StateObject private var bottomSheet = ThreadBottomSheet()
    @StateObject private var networkMonitor = NetworkMonitor()

    let isCompact: Bool

    private let bottomSheetOptions = Constants.bottomSheetOptions + [.appleScrollBehavior]

    init(mailboxManager: MailboxManager, folder: Binding<Folder?>, isCompact: Bool) {
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(mailboxManager: mailboxManager, folder: folder.wrappedValue))
        _currentFolder = folder
        self.isCompact = isCompact

        UITableViewCell.appearance().focusEffect = .none
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(MailResourcesAsset.backgroundColor.color)
                .ignoresSafeArea()

            if viewModel.threads.isEmpty {
                EmptyListView()
            }

            List {
                if !networkMonitor.isConnected {
                    NoNetworkView()
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 0, leading: 8, bottom: 0, trailing: 8))
                }

                ForEach(viewModel.threads) { thread in
                    Group {
                        if currentFolder?.role == .draft {
                            Button(action: {
                                editDraft(from: thread)
                            }, label: {
                                ThreadListCell(mailboxManager: viewModel.mailboxManager, thread: thread)
                            })
                        } else {
                            NavigationLink(destination: {
                                ThreadView(mailboxManager: viewModel.mailboxManager, thread: thread)
                                    .onAppear { selectedThread = thread }
                            }, label: {
                                ThreadListCell(mailboxManager: viewModel.mailboxManager, thread: thread)
                            })
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(selectedThread == thread
                            ? MailResourcesAsset.backgroundCardSelectedColor.color
                            : MailResourcesAsset.backgroundColor.color))
                    .modifier(ThreadListSwipeAction(thread: thread, viewModel: viewModel, bottomSheet: bottomSheet))
                    .onAppear {
                        viewModel.loadNextPageIfNeeded(currentItem: thread)
                    }
                }

                if viewModel.isLoadingPage {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
            .listStyle(.plain)
            .introspectTableView { tableView in
                tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
            }

            NewMessageButtonView(sheet: menuSheet)
                .padding([.trailing, .bottom], 30)

            NavigationLink(isActive: $settingsSheet.isShowing) {
                switch settingsSheet.state {
                case .settings:
                    SettingsView()
                case .manageAccount:
                    AccountView()
                case .none:
                    EmptyView()
                }
            } label: {
                EmptyView()
            }
        }
        .backButtonDisplayMode(.minimal)
        .introspectNavigationController { navigationController in
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithTransparentBackground()
            navigationBarAppearance.backgroundColor = MailResourcesAsset.backgroundHeaderColor.color
            navigationBarAppearance.largeTitleTextAttributes = [
                .foregroundColor: MailResourcesAsset.primaryTextColor.color,
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold)
            ]

            navigationController.navigationBar.tintColor = MailResourcesAsset.secondaryTextColor.color
            navigationController.navigationBar.standardAppearance = navigationBarAppearance
            navigationController.navigationBar.compactAppearance = navigationBarAppearance
            navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance
            // navigationController.hidesBarsOnSwipe = true
        }
        .modifier(ThreadListNavigationBar(isCompact: isCompact, folder: $viewModel.folder, avatarImage: $avatarImage))
        .sheet(isPresented: $menuSheet.isShowing) {
            switch menuSheet.state {
            case .newMessage:
                NewMessageView(isPresented: $menuSheet.isShowing, mailboxManager: viewModel.mailboxManager)
            case let .editMessage(draft):
                NewMessageView(isPresented: $menuSheet.isShowing, mailboxManager: viewModel.mailboxManager, draft: draft.asUnmanaged())
            case .addAccount:
                LoginView(isPresented: $menuSheet.isShowing)
            case .none:
                EmptyView()
            }
        }
        .bottomSheet(bottomSheetPosition: $bottomSheet.position, options: bottomSheetOptions) {
            switch bottomSheet.state {
            case let .actions(target):
                if target.isInvalidated {
                    EmptyView()
                } else {
                    ActionsView(mailboxManager: viewModel.mailboxManager, target: target, state: bottomSheet)
                }
            default:
                EmptyView()
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            if isCompact {
                selectedThread = nil
            }
            networkMonitor.start()
        }
        .onDisappear {
            networkMonitor.stop()
        }
        .onChange(of: currentFolder) { newFolder in
            guard let folder = newFolder else { return }
            selectedThread = nil
            viewModel.updateThreads(with: folder)
        }
        .task {
            if let account = AccountManager.instance.currentAccount {
                avatarImage = await account.user.getAvatar()
            }
            if let folder = currentFolder {
                viewModel.updateThreads(with: folder)
            }
        }
        .refreshable {
            await viewModel.fetchThreads()
        }
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

private struct ThreadListNavigationBar: ViewModifier {
    var isCompact: Bool

    @Binding var folder: Folder?
    @Binding var avatarImage: Image

    @EnvironmentObject var navigationDrawerController: NavigationDrawerController

    func body(content: Content) -> some View {
        content
            .navigationTitle(folder?.localizedName ?? "")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SearchBarButtonView()
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AccountListView()
                    } label: {
                        avatarImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    }
                }
            }
            .modifyIf(isCompact) { view in
                view.toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            navigationDrawerController.open()
                        } label: {
                            Image(resource: MailResourcesAsset.burger)
                        }
                    }
                }
            }
    }
}

private struct ThreadListSwipeAction: ViewModifier {
    let thread: Thread
    let viewModel: ThreadListViewModel
    @ObservedObject var bottomSheet: ThreadBottomSheet

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                Button {
                    Task {
                        await viewModel.toggleRead(thread: thread)
                    }
                } label: {
                    Image(resource: thread.unseenMessages > 0 ? MailResourcesAsset.envelopeOpen : MailResourcesAsset.envelope)
                }
                .tint(MailResourcesAsset.unreadActionColor)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    Task {
                        await viewModel.delete(thread: thread)
                    }
                } label: {
                    Image(resource: MailResourcesAsset.bin)
                }
                .tint(MailResourcesAsset.destructiveActionColor)

                Button {
                    bottomSheet.open(state: .actions(.thread(thread.thaw() ?? thread)), position: .middle)
                } label: {
                    Image(resource: MailResourcesAsset.navigationMenu)
                }
                .tint(MailResourcesAsset.menuActionColor)
            }
    }
}

struct ThreadListView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListView(
            mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()),
            folder: .constant(PreviewHelper.sampleFolder),
            isCompact: false
        )
    }
}
