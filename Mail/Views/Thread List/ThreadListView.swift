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

@MainActor struct ThreadListView: View {
    @State private var presentMenuDrawer = false

    private var viewModel: ThreadListViewModel

    let isCompact: Bool

    init(mailboxManager: MailboxManager, folder: Folder?, isCompact: Bool) {
        viewModel = ThreadListViewModel(mailboxManager: mailboxManager, folder: folder)
        self.isCompact = isCompact
    }

    var body: some View {
        List(viewModel.threads) { thread in
            ZStack {
                NavigationLink(destination: ThreadView(mailboxManager: viewModel.mailboxManager, thread: thread)) {
                    EmptyView()
                }
                .opacity(0)

                ThreadListCell(mailboxManager: viewModel.mailboxManager, thread: thread)
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(PlainListStyle())
        .navigationTitle(viewModel.folder?.localizedName ?? "")
        .if(isCompact) { view in
            view.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentMenuDrawer.toggle()
                    } label: {
                        Image(uiImage: MailResourcesAsset.burger.image)
                    }
                }
            }
        }
        .sheet(isPresented: $presentMenuDrawer, content: {
            MenuDrawerView(mailboxManager: viewModel.mailboxManager, selectedFolderId: viewModel.folder?.id, isCompact: isCompact)
        })
        .task {
            await viewModel.fetchThreads()
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
