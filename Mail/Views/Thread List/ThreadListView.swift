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
        case reply(Message, ReplyMode)
        case editMessage(draft: Draft)
        case addAccount
        case manageAccount
        case switchAccount
        case settings
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
    @EnvironmentObject var globalBottomSheet: GlobalBottomSheet

    @Binding var currentFolder: Folder?

    @State private var avatarImage = Image(resource: MailResourcesAsset.placeholderAvatar)
    @State private var selectedThread: Thread?
    @StateObject var bottomSheet: ThreadBottomSheet
    @StateObject private var networkMonitor = NetworkMonitor()

    let isCompact: Bool

    private let bottomSheetOptions = Constants.bottomSheetOptions + [.appleScrollBehavior]

    init(mailboxManager: MailboxManager, folder: Binding<Folder?>, isCompact: Bool) {
        let threadBottomSheet = ThreadBottomSheet()
        _bottomSheet = StateObject(wrappedValue: threadBottomSheet)
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(mailboxManager: mailboxManager,
                                                                   folder: folder.wrappedValue,
                                                                   bottomSheet: threadBottomSheet))
        _currentFolder = folder
        self.isCompact = isCompact

        UITableViewCell.appearance().focusEffect = .none
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(MailResourcesAsset.backgroundColor.color)
                .ignoresSafeArea()

            if viewModel.threads.isEmpty && !viewModel.isLoadingPage {
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
                    .modifier(ThreadListSwipeAction(thread: thread, viewModel: viewModel))
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
        }
        .backButtonDisplayMode(.minimal)
        .navigationBarAppStyle()
        .modifier(ThreadListNavigationBar(isCompact: isCompact, folder: $viewModel.folder, avatarImage: $avatarImage))
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
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            if isCompact {
                selectedThread = nil
            }
            networkMonitor.start()
            viewModel.globalBottomSheet = globalBottomSheet
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

    @EnvironmentObject var menuSheet: MenuSheet
    @EnvironmentObject var navigationDrawerController: NavigationDrawerController

    func body(content: Content) -> some View {
        content
            .navigationTitle(folder?.localizedName ?? "")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SearchBarButtonView()
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        menuSheet.state = .switchAccount
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

private struct SwipeActionView: View {
    let thread: Thread
    let viewModel: ThreadListViewModel
    let action: SwipeAction

    var icon: Image? {
        if action == .readUnread {
            return Image(resource: thread.unseenMessages == 0 ? MailResourcesAsset.envelope : MailResourcesAsset.envelopeOpen)
        }
        return action.swipeIcon
    }

    var body: some View {
        Button {
            Task {
                await tryOrDisplayError {
                    try await viewModel.hanldeSwipeAction(action, thread: thread)
                }
            }
        } label: {
            Label { Text(action.title) } icon: { icon }
        }
        .tint(action.swipeTint)
    }
}

private struct ThreadListSwipeAction: ViewModifier {
    let thread: Thread
    let viewModel: ThreadListViewModel

    @AppStorage(UserDefaults.shared.key(.swipeLongRight)) private var swipeLongRight = SwipeAction.none
    @AppStorage(UserDefaults.shared.key(.swipeShortRight)) private var swipeShortRight = SwipeAction.none

    @AppStorage(UserDefaults.shared.key(.swipeLongLeft)) private var swipeLongLeft = SwipeAction.none
    @AppStorage(UserDefaults.shared.key(.swipeShortLeft)) private var swipeShortLeft = SwipeAction.none

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                edgeActions([swipeLongRight, swipeShortRight])
            }
            .swipeActions(edge: .trailing) {
                edgeActions([swipeLongLeft, swipeShortLeft])
            }
    }

    func edgeActions(_ actions: [SwipeAction]) -> some View {
        ForEach(actions.filter { $0 != .none }, id: \.rawValue) { action in
            SwipeActionView(thread: thread, viewModel: viewModel, action: action)
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
        .environmentObject(MenuSheet())
    }
}
