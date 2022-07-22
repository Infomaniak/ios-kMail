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

extension ThreadDensity {
    var cellVerticalPadding: CGFloat {
        self == .compact ? 8 : 16
    }

    var unreadCircleTopPadding: CGFloat {
        self == .large ? 12 : 6
    }
}

struct ThreadListCell: View {
    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    @State private var isLinkEnabled = false

    var thread: Thread
    var navigationController: UINavigationController?

    private var isInDraftFolder: Bool {
        return viewModel.folder?.role == .draft
    }

    private var isSelected: Bool {
        return multipleSelectionViewModel.editMode == .active &&
        multipleSelectionViewModel.selectedItems.contains(thread)
    }

    var body: some View {
        ZStack {
            if !isInDraftFolder {
                NavigationLink(destination: ThreadView(mailboxManager: viewModel.mailboxManager,
                                                       thread: thread,
                                                       navigationController: navigationController),
                               isActive: $isLinkEnabled) {
                    EmptyView()
                }
                .opacity(0)
            }

            ThreadListCellContent(mailboxManager: viewModel.mailboxManager, thread: thread)
        }
        .tag(thread)
        .onTapGesture {
            if multipleSelectionViewModel.editMode == .inactive {
                viewModel.selectedThread = thread
                if isInDraftFolder {
                    viewModel.editDraft(from: thread)
                } else {
                    isLinkEnabled = true
                }
            } else {
                multipleSelectionViewModel.toggleSelect(thread: thread)
            }
        }
        .onLongPressGesture {
            withAnimation {
                multipleSelectionViewModel.editMode = .active
            }
        }
        .modifyIf(isSelected) { view in
            view
                .background(SelectionBackground())
        }
    }
}

private struct ThreadListCellContent: View {
    @AppStorage(UserDefaults.shared.key(.threadDensity)) var density: ThreadDensity = .normal

    var mailboxManager: MailboxManager
    var thread: Thread

    private var hasUnreadMessages: Bool {
        thread.unseenMessages > 0
    }

    private var textStyle: MailTextStyle {
        hasUnreadMessages ? .header3 : .bodySecondary
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .frame(width: Constants.unreadIconSize, height: Constants.unreadIconSize)
                .foregroundColor(hasUnreadMessages ? Color.accentColor : .clear)
                .padding(.top, density.unreadCircleTopPadding)

            if density == .large, let recipient = thread.from.last {
                RecipientImage(recipient: recipient, size: 32)
                    .padding(.trailing, 2)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    if thread.hasDrafts {
                        Text("(\(MailResourcesStrings.Localizable.messageIsDraftOption))")
                            .foregroundColor(MailResourcesAsset.redActionColor)
                            .textStyle(hasUnreadMessages ? .header2 : .header2Secondary)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                    Text(thread.messages.allSatisfy(\.isDraft) ? thread.formattedTo : thread.formattedFrom)
                        .textStyle(hasUnreadMessages ? .header2 : .header2Secondary)
                        .lineLimit(1)

                    Spacer()

                    if thread.hasAttachments {
                        Image(resource: MailResourcesAsset.attachmentMail1)
                            .foregroundColor(textStyle.color)
                            .frame(height: 10)
                    }

                    Text(thread.date.customRelativeFormatted)
                        .textStyle(hasUnreadMessages ? .calloutStrong : .calloutSecondary)
                        .lineLimit(1)
                }
                .padding(.bottom, 4)

                HStack(alignment: .top, spacing: 3) {
                    VStack(alignment: .leading) {
                        Text(thread.formattedSubject)
                            .textStyle(textStyle)
                            .lineLimit(1)

                        if density != .compact,
                           let preview = thread.messages.last?.preview,
                           !preview.isEmpty {
                            Text(preview)
                                .textStyle(.bodySecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        if thread.flagged {
                            Image(resource: MailResourcesAsset.starFull)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }

                        if thread.messagesCount > 1 {
                            Text("\(thread.messagesCount)")
                                .textStyle(.bodySecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(.vertical, density.cellVerticalPadding)
    }
}

struct ThreadListCell_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadListViewModel(mailboxManager: PreviewHelper.sampleMailboxManager,
                                            folder: nil,
                                            bottomSheet: ThreadBottomSheet())

        ThreadListCell(viewModel: viewModel,
                       multipleSelectionViewModel: ThreadListMultipleSelectionViewModel(),
                       thread: PreviewHelper.sampleThread)
        .previewLayout(.sizeThatFits)
        .previewDevice("iPhone 13 Pro")
    }
}
