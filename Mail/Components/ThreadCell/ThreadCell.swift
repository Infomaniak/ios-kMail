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

extension Animation {
    static var threadListSlide: Animation {
        .default.speed(2)
    }
}

extension ThreadDensity {
    var cellVerticalPadding: CGFloat {
        self == .compact ? 10 : 12
    }
}

struct ThreadCellDataHolder {
    /// Sender of the last message that is not in the Sent folder, otherwise the last message of the thread
    let recipientToDisplay: Recipient?

    /// Date of the last message of the folder, otherwise the last message of the thread
    let date: String

    /// Subject of the first message
    let subject: String

    /// Last message of the thread, except for the Sent folder where we use the last message of the folder
    let preview: String

    let isInWrittenByMeFolder: Bool

    init(thread: Thread) {
        let lastMessageNotFromSent = thread.messages.last { $0.folder?.role != .sent } ?? thread.messages.last
        date = thread.date.customRelativeFormatted

        subject = thread.formattedSubject

        isInWrittenByMeFolder = FolderRole.writtenByMeFolders.contains { $0 == thread.folder?.role }

        let content: String?
        if isInWrittenByMeFolder {
            recipientToDisplay = lastMessageNotFromSent?.to.first
            content = (thread.lastMessageFromFolder ?? thread.messages.last)?.preview
        } else {
            recipientToDisplay = lastMessageNotFromSent?.from.first
            content = thread.messages.last?.preview
        }

        if let content, !content.isEmpty {
            preview = content
        } else {
            preview = MailResourcesStrings.Localizable.noBodyTitle
        }
    }

    func contactConfiguration(contextMailboxManager: MailboxManager) -> ContactConfiguration {
        if let recipientToDisplay {
            return .correspondent(correspondent: recipientToDisplay, contextMailboxManager: contextMailboxManager)
        } else {
            return .emptyContact
        }
    }
}

extension ThreadCell: Equatable {
    static func == (lhs: ThreadCell, rhs: ThreadCell) -> Bool {
        return lhs.thread.id == rhs.thread.id
            && lhs.thread.messageIds == rhs.thread.messageIds
            && lhs.isSelected == rhs.isSelected
            && lhs.isMultipleSelectionEnabled == rhs.isMultipleSelectionEnabled
    }
}

struct ThreadCell: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    /// With normal or compact density, the checkbox should appear and disappear at different times of the cell offset.
    @State private var shouldDisplayCheckbox = false

    let thread: Thread

    let dataHolder: ThreadCellDataHolder

    let accentColor: AccentColor
    let density: ThreadDensity
    let isMultipleSelectionEnabled: Bool
    let isSelected: Bool
    let avatarTapped: (() -> Void)?

    private var checkboxSize: CGFloat {
        density == .large ? UIConstants.checkboxLargeSize : UIConstants.checkboxSize
    }

    private var additionalAccessibilityLabel: String {
        var label = ""
        if isSelected {
            label.append("\(MailResourcesStrings.Localizable.contentDescriptionSelectedItem). ")
        }
        if thread.hasUnseenMessages {
            label.append(MailResourcesStrings.Localizable.actionShortMarkAsUnread)
        }
        return label
    }

    init(
        thread: Thread,
        density: ThreadDensity,
        accentColor: AccentColor,
        isMultipleSelectionEnabled: Bool = false,
        isSelected: Bool = false,
        avatarTapped: (() -> Void)? = nil
    ) {
        self.thread = thread

        dataHolder = ThreadCellDataHolder(thread: thread)

        self.density = density
        self.accentColor = accentColor
        self.isMultipleSelectionEnabled = isMultipleSelectionEnabled
        self.isSelected = isSelected
        self.avatarTapped = avatarTapped
    }

    // MARK: - Views

    var body: some View {
        HStack(spacing: UIPadding.small) {
            UnreadIndicatorView(hidden: !thread.hasUnseenMessages)
                .accessibilityLabel(additionalAccessibilityLabel)
                .accessibilityHidden(additionalAccessibilityLabel.isEmpty)

            ThreadCellAvatarCheckboxView(
                accentColor: accentColor,
                density: density,
                isSelected: isSelected,
                isMultipleSelectionEnabled: isMultipleSelectionEnabled,
                shouldDisplayCheckbox: shouldDisplayCheckbox,
                contactConfiguration: dataHolder.contactConfiguration(contextMailboxManager: mailboxManager),
                avatarTapped: avatarTapped
            )
            .padding(.trailing, value: .verySmall)

            VStack(alignment: .leading, spacing: UIPadding.verySmall) {
                ThreadCellHeaderView(
                    recipientsTitle: thread.formatted(contextMailboxManager: mailboxManager,
                                                      style: dataHolder.isInWrittenByMeFolder ? .to : .from),
                    messageCount: thread.messages.count,
                    prominentMessageCount: thread.hasUnseenMessages,
                    formattedDate: dataHolder.date,
                    showDraftPrefix: thread.hasDrafts
                )

                ThreadCellBodyView(
                    subject: dataHolder.subject,
                    preview: dataHolder.preview,
                    density: density,
                    folderName: thread.searchFolderName,
                    hasAttachments: thread.hasAttachments,
                    isFlagged: thread.flagged
                )
            }
            .animation(
                isMultipleSelectionEnabled ? .threadListSlide : .threadListSlide.delay(UIConstants.checkboxDisappearOffsetDelay),
                value: isMultipleSelectionEnabled
            )
        }
        .padding(.leading, value: .small)
        .padding(.trailing, value: .regular)
        .padding(.vertical, density.cellVerticalPadding)
        .clipped()
        .accessibilityElement(children: .combine)
        .onChange(of: isMultipleSelectionEnabled, perform: animateCheckbox)
    }

    private func animateCheckbox(_ isEnabled: Bool) {
        guard density != .large else { return }

        withAnimation {
            if isEnabled {
                // We should wait a bit before showing the checkbox
                DispatchQueue.main.asyncAfter(deadline: .now() + UIConstants.checkboxAppearDelay) {
                    shouldDisplayCheckbox = true
                }
            } else {
                shouldDisplayCheckbox = false
            }
        }
    }
}

#Preview {
    List {
        ThreadCell(thread: PreviewHelper.sampleThread,
                   density: .large,
                   accentColor: .blue,
                   isMultipleSelectionEnabled: false,
                   isSelected: false)
        ThreadCell(thread: PreviewHelper.sampleThread,
                   density: .normal,
                   accentColor: .blue,
                   isMultipleSelectionEnabled: false,
                   isSelected: false)
        ThreadCell(thread: PreviewHelper.sampleThread,
                   density: .compact,
                   accentColor: .blue,
                   isMultipleSelectionEnabled: false,
                   isSelected: false)
    }
    .listStyle(.plain)
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
