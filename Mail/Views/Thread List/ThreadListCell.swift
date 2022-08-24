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
}

struct ThreadListCell: View {
    @AppStorage(UserDefaults.shared.key(.threadDensity)) var density: ThreadDensity = .normal
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = AccentColor.pink

    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    @State private var shouldNavigateToThreadList = false

    var thread: Thread
    var navigationController: UINavigationController?

    private var isInDraftFolder: Bool {
        viewModel.folder?.role == .draft
    }
    private var hasUnreadMessages: Bool {
        thread.unseenMessages > 0
    }
    private var isSelected: Bool {
        multipleSelectionViewModel.selectedItems.map(\.id).contains(thread.id)
    }
    private var textStyle: MailTextStyle {
        hasUnreadMessages ? .header3 : .bodySecondary
    }

    private var checkboxSize: CGFloat {
        density == .compact ? Constants.checkboxCompactSize : Constants.checkboxSize
    }
    private var checkmarkSize: CGFloat {
        density == .compact ? Constants.checkmarkCompactSize : Constants.checkmarkSize
    }

    // MARK: - Views

    var body: some View {
        ZStack {
            linkToThreadView

            HStack(spacing: 8) {
                unreadIndicator

                Group {
                    if density == .large && !isSelected, let recipient = thread.from.last {
                        if isSelected {
                            checkbox
                        } else {
                            RecipientImage(recipient: recipient, size: 32)
                        }
                    } else if multipleSelectionViewModel.isEnabled {
                        checkbox
                    }
                }
                .padding(.trailing, 4)

                VStack(alignment: .leading, spacing: 4) {
                    cellHeader

                    HStack(alignment: .top, spacing: 3) {
                        threadInfo
                        Spacer()
                        threadDetails
                    }
                }
            }
        }
        .padding(.leading, multipleSelectionViewModel.isEnabled ? 16 : 8)
        .padding(.trailing, 12)
        .padding(.vertical, density.cellVerticalPadding)
        .background( isSelected ?
            RoundedRectangle(cornerRadius: 10)
                .fill(accentColor.secondary.swiftUiColor)
                .offset(x: 8, y: 0)
                .padding(.vertical, 2)
             : nil
        )
        .onTapGesture(perform: didTapCell)
        .onLongPressGesture(minimumDuration: 0.3, perform: didLongPressCell)
        .swipeActions(thread: thread, viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
    }

    @ViewBuilder
    private var linkToThreadView: some View {
        if !isInDraftFolder {
            NavigationLink(destination: ThreadView(mailboxManager: viewModel.mailboxManager,
                                                   thread: thread,
                                                   folderId: viewModel.folder?.id,
                                                   navigationController: navigationController),
                           isActive: $shouldNavigateToThreadList) { EmptyView() }
                .opacity(0)
                .disabled(multipleSelectionViewModel.isEnabled)
        }
    }

    private var unreadIndicator: some View {
        Circle()
            .frame(width: Constants.unreadIconSize, height: Constants.unreadIconSize)
            .foregroundColor(hasUnreadMessages ? Color.accentColor : .clear)
    }

    private var checkbox: some View {
        Circle()
            .strokeBorder(Color.accentColor, lineWidth: 2)
            .background(Circle().fill(isSelected ? Color.accentColor : Color.clear))
            .frame(width: checkboxSize, height: checkboxSize)
            .overlay {
                if isSelected {
                    Image(resource: MailResourcesAsset.check)
                        .foregroundColor(.white)
                        .frame(height: checkmarkSize)
                }
            }
    }

    private var cellHeader: some View {
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

            if thread.messagesCount > 1 {
                Text("\(thread.messagesCount)")
                    .textStyle(.bodySecondary)
                    .padding(.horizontal, 3)
                    .lineLimit(1)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.gray)
                    }
            }

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
    }

    private var threadInfo: some View {
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
    }

    private var threadDetails: some View {
        VStack(spacing: 4) {
            if thread.flagged {
                Image(resource: MailResourcesAsset.starFull)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
        }
    }

    // MARK: - Actions

    private func didTapCell() {
        if !multipleSelectionViewModel.isEnabled {
            viewModel.selectedThread = thread
            if isInDraftFolder {
                viewModel.editDraft(from: thread)
            } else {
                shouldNavigateToThreadList = true
            }
        } else {
            multipleSelectionViewModel.toggleSelection(of: thread)
        }
    }

    private func didLongPressCell() {
        withAnimation {
            multipleSelectionViewModel.isEnabled.toggle()
            if multipleSelectionViewModel.isEnabled {
                multipleSelectionViewModel.toggleSelection(of: thread)
            }
        }
    }
}

struct ThreadListCell_Previews: PreviewProvider {
    static var previews: some View {
        let userDefaultsList = [
            updateUserDefaults(threadDensity: .compact),
            updateUserDefaults(threadDensity: .normal),
            updateUserDefaults(threadDensity: .large)
        ]

        let viewModel = ThreadListViewModel(mailboxManager: PreviewHelper.sampleMailboxManager,
                                            folder: nil,
                                            bottomSheet: ThreadBottomSheet())
        let multipleSelectionViewModel = ThreadListMultipleSelectionViewModel(mailboxManager: PreviewHelper.sampleMailboxManager)
        let selectedMultipleSelectionViewModel = ThreadListMultipleSelectionViewModel(mailboxManager: PreviewHelper.sampleMailboxManager)

        VStack(alignment: .leading) {
            ForEach(userDefaultsList, id: \.self) { userDefaults in
                ThreadListCell(viewModel: viewModel,
                               multipleSelectionViewModel: multipleSelectionViewModel,
                               thread: PreviewHelper.sampleThread)
                .defaultAppStorage(userDefaults)
            }

            Divider()

            ForEach(userDefaultsList, id: \.self) { userDefaults in
                ThreadListCell(viewModel: viewModel,
                               multipleSelectionViewModel: selectedMultipleSelectionViewModel,
                               thread: PreviewHelper.sampleThread)
                .defaultAppStorage(userDefaults)
            }
        }
        .onAppear {
            selectedMultipleSelectionViewModel.isEnabled = true
            selectedMultipleSelectionViewModel.toggleSelection(of: PreviewHelper.sampleThread)
        }
        .previewLayout(.sizeThatFits)
        .previewDevice("iPhone 13 Pro")
    }

    static func updateUserDefaults(threadDensity: ThreadDensity) -> UserDefaults {
        let userDefaults = UserDefaults(suiteName: "userdefaults_\(threadDensity.rawValue)")!
        userDefaults.set(threadDensity.rawValue, forKey: userDefaults.key(.threadDensity))
        return userDefaults
    }
}
