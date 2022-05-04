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

class ThreadListSheet: SheetState<ThreadListSheet.State> {
    enum State: Equatable {
        case menuDrawer
        case newMessage
    }
}

struct ThreadListView: View {
    @StateObject var viewModel: ThreadListViewModel
    @StateObject var sheet = ThreadListSheet()

    @Binding var currentFolder: Folder?

    @State private var avatarImage = Image(uiImage: MailResourcesAsset.placeholderAvatar.image)
    @State private var selectedThread: Thread?

    let isCompact: Bool
    let geometryProxy: GeometryProxy?

    init(mailboxManager: MailboxManager, folder: Binding<Folder?>, isCompact: Bool, geometryProxy: GeometryProxy? = nil) {
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(mailboxManager: mailboxManager, folder: folder.wrappedValue))
        _currentFolder = folder
        self.isCompact = isCompact
        self.geometryProxy = geometryProxy

        UITableViewCell.appearance().focusEffect = .none
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(MailResourcesAsset.backgroundColor.color)
                .ignoresSafeArea()

            List(viewModel.threads) { thread in
                // Useful to hide the NavigationLink accessoryType
                ZStack {
                    NavigationLink(destination: {
                        ThreadView(mailboxManager: viewModel.mailboxManager, thread: thread)
                            .onAppear { selectedThread = thread }
                    }, label: { EmptyView() })
                    .opacity(0)

                    ThreadListCell(mailboxManager: viewModel.mailboxManager, thread: thread)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color(selectedThread == thread ? MailResourcesAsset.backgroundHeaderColor.color : MailResourcesAsset.backgroundColor.color))
                .modifier(ThreadListSwipeAction())
            }
            .listStyle(.plain)

            NewMessageButtonView(sheet: sheet)
                .padding(.trailing, 30)
                .padding(.bottom, max(8, 30 - (geometryProxy?.safeAreaInsets.bottom ?? 0)))
        }
        .introspectNavigationController { navigationController in
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithTransparentBackground()
            navigationBarAppearance.backgroundColor = MailResourcesAsset.backgroundHeaderColor.color
            navigationBarAppearance.largeTitleTextAttributes = [
                .foregroundColor: MailResourcesAsset.primaryTextColor.color,
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold)
            ]

            navigationController.navigationBar.standardAppearance = navigationBarAppearance
            navigationController.navigationBar.compactAppearance = navigationBarAppearance
            navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        }
        .modifier(ThreadListNavigationBar(isCompact: isCompact, sheet: sheet, folder: $viewModel.folder, avatarImage: $avatarImage))
        .sheet(isPresented: $sheet.isShowing) {
            switch sheet.state {
            case .menuDrawer:
                MenuDrawerView(mailboxManager: viewModel.mailboxManager, selectedFolder: $currentFolder, isCompact: isCompact)
            case .newMessage:
                NewMessageView(mailboxManager: viewModel.mailboxManager)
            case .none:
                EmptyView()
            }
        }
        .onAppear {
            if isCompact {
                selectedThread = nil
            }
        }
        .onChange(of: currentFolder) { newFolder in
            guard let folder = newFolder else { return }
            selectedThread = nil
            viewModel.updateThreads(with: folder)
        }
        .task {
            avatarImage = await AccountManager.instance.currentAccount.user.getAvatar()
        }
        .refreshable {
            await viewModel.fetchThreads()
        }
    }
}

private struct ThreadListNavigationBar: ViewModifier {
    var isCompact: Bool

    @ObservedObject var sheet: ThreadListSheet

    @Binding var folder: Folder?
    @Binding var avatarImage: Image

    func body(content: Content) -> some View {
        content
            .navigationTitle(folder?.localizedName ?? "")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SearchBarButtonView()
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Display accounts list
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
                            sheet.state = .menuDrawer
                        } label: {
                            Image(uiImage: MailResourcesAsset.burger.image)
                        }
                        .tint(MailResourcesAsset.secondaryTextColor)
                    }
                }
            }
    }
}

private struct ThreadListSwipeAction: ViewModifier {
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    // TODO: Mark the message as (un)read
                } label: {
                    Image(uiImage: MailResourcesAsset.openLetter.image)
                }
                .tint(MailResourcesAsset.unreadActionColor)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    // TODO: Delete thread
                } label: {
                    Image(uiImage: MailResourcesAsset.bin.image)
                }
                .tint(MailResourcesAsset.destructiveActionColor)

                Button {
                    // TODO: Display menu
                } label: {
                    Image(uiImage: MailResourcesAsset.threeDots.image)
                }
                .tint(MailResourcesAsset.menuActionColor)
            }
    }
}

struct ThreadListView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            ThreadListView(
                mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()),
                folder: .constant(PreviewHelper.sampleFolder),
                isCompact: false,
                geometryProxy: geometry
            )
        }
    }
}
