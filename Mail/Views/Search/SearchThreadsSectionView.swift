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

struct SearchThreadsSectionView: View {
    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity

    let viewModel: SearchViewModel
    @Binding var editedMessageDraft: Draft?

    var body: some View {
        Section {
            ForEach(viewModel.threads) { thread in
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
            if threadDensity != .compact && !viewModel.threads.isEmpty {
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
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUIColor)
    }
}
