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


struct ThreadListView: View, FolderListViewDelegate {
    @ObservedObject var viewModel: ThreadListViewModel

    @State private var presentMenuDrawer = false
    @State private var presentNewMessageEditor = false

    @State private var avatarImage = MailResourcesAsset.placeholderAvatar.image

    let isCompact: Bool

    init(mailboxManager: MailboxManager, folder: Folder?, isCompact: Bool) {
        viewModel = ThreadListViewModel(mailboxManager: mailboxManager, folder: folder)
        self.isCompact = isCompact
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List(viewModel.threads) { thread in
                ZStack {
                    NavigationLink(destination: ThreadView(mailboxManager: viewModel.mailboxManager, thread: thread)) {
                        EmptyView()
                    }
                    .opacity(0)
                    ThreadListCell(mailboxManager: viewModel.mailboxManager, thread: thread)
                }
                .listRowSeparator(.hidden)
                .modifier(ThreadListSwipeAction())
            }
            .listStyle(PlainListStyle())

            NewMessageButtonView(presentNewMessageEditor: $presentNewMessageEditor)
                .padding(.trailing, 30)
                .padding(.bottom, 25)
        }
        .modifier(ThreadListNavigationBar(isCompact: isCompact, title: viewModel.folder?.name, presentMenuDrawer: $presentMenuDrawer, avatarImage: $avatarImage))
        .sheet(isPresented: $presentMenuDrawer) {
            MenuDrawerView(mailboxManager: viewModel.mailboxManager, selectedFolderId: viewModel.folder?.id, isCompact: isCompact, delegate: self)
        }
        .sheet(isPresented: $presentNewMessageEditor) {
            NewMessageView(mailboxManager: viewModel.mailboxManager)
        }
        .refreshable {
            await viewModel.fetchThreads()
        }
        .task {
            await viewModel.fetchThreads()
            AccountManager.instance.currentAccount.user.getAvatar { image in
                avatarImage = image
            }
        }
    }

    func didSelectFolder(_ folder: Folder) {
        viewModel.updateThreads(with: folder)
    }
}

private struct ThreadListNavigationBar: ViewModifier {
    var isCompact: Bool

    @State var title: String?

    @Binding var presentMenuDrawer: Bool
    @Binding var avatarImage: UIImage

    func body(content: Content) -> some View {
        content
            .navigationTitle(title ?? "")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Display accounts list
                    } label: {
                        Image(uiImage: avatarImage)
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
                            presentMenuDrawer.toggle()
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
        ThreadListView(mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()),
                       folder: PreviewHelper.sampleFolder,
                       isCompact: false)
    }
}
