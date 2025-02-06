/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import DesignSystem
import InfomaniakCore
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
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

extension ThreadCell: Equatable {
    // TODO: Maybe remove this check now that we don't have performance issues ?
    static func == (lhs: ThreadCell, rhs: ThreadCell) -> Bool {
        return lhs.thread.id == rhs.thread.id
            && lhs.isSelected == rhs.isSelected
            && lhs.isMultipleSelectionEnabled == rhs.isMultipleSelectionEnabled
            && lhs.thread == rhs.thread
    }
}

struct ThreadCell: View {
    /// With normal or compact density, the checkbox should appear and disappear at different times of the cell offset.
    @State private var shouldDisplayCheckbox = false

    // let thread: Thread

    let thread: ThreadUI

    let accentColor: AccentColor
    let density: ThreadDensity
    let isMultipleSelectionEnabled: Bool
    let isSelected: Bool
    let avatarTapped: (() -> Void)?

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
        contextUser: UserProfile,
        contextMailboxManager: MailboxManager,
        density: ThreadDensity,
        accentColor: AccentColor,
        isMultipleSelectionEnabled: Bool = false,
        isSelected: Bool = false,
        avatarTapped: (() -> Void)? = nil
    ) {
        self.thread = ThreadUI(thread: thread, contextUser: contextUser, contextMailboxManager: contextMailboxManager)

        self.density = density
        self.accentColor = accentColor
        self.isMultipleSelectionEnabled = isMultipleSelectionEnabled
        self.isSelected = isSelected
        self.avatarTapped = avatarTapped
    }

    // MARK: - Views

    var body: some View {
        HStack(spacing: IKPadding.mini) {
            UnreadIndicatorView(hidden: !thread.hasUnseenMessages)
                .accessibilityLabel(additionalAccessibilityLabel)
                .accessibilityHidden(additionalAccessibilityLabel.isEmpty)

            ThreadCellAvatarCheckboxView(
                accentColor: accentColor,
                density: density,
                isSelected: isSelected,
                isMultipleSelectionEnabled: isMultipleSelectionEnabled,
                shouldDisplayCheckbox: shouldDisplayCheckbox,
                contactConfiguration: thread.contactConfiguration,
                avatarTapped: avatarTapped
            )
            .padding(.trailing, value: .micro)

            VStack(alignment: .leading, spacing: IKPadding.micro) {
                ThreadCellHeaderView(
                    recipientsTitle: thread.recipientsTitle,
                    messageCount: thread.messageCount,
                    prominentMessageCount: thread.hasUnseenMessages,
                    date: thread.date,
                    showDraftPrefix: thread.hasDrafts
                )

                ThreadCellBodyView(
                    email: thread.additionalEmail,
                    subject: thread.subject,
                    preview: thread.preview,
                    density: density,
                    folderName: thread.searchFolderName,
                    lastAction: thread.lastAction,
                    hasAttachments: thread.hasAttachments,
                    isFlagged: thread.flagged
                )
            }
            .animation(
                isMultipleSelectionEnabled ? .threadListSlide : .threadListSlide.delay(0.35),
                value: isMultipleSelectionEnabled
            )
        }
        .padding(.leading, value: .mini)
        .padding(.trailing, value: .medium)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
                   contextUser: PreviewHelper.sampleUser,
                   contextMailboxManager: PreviewHelper.sampleMailboxManager,
                   density: .large,
                   accentColor: .blue,
                   isMultipleSelectionEnabled: false,
                   isSelected: false)
        ThreadCell(thread: PreviewHelper.sampleThread,
                   contextUser: PreviewHelper.sampleUser,
                   contextMailboxManager: PreviewHelper.sampleMailboxManager,
                   density: .normal,
                   accentColor: .blue,
                   isMultipleSelectionEnabled: false,
                   isSelected: false)
        ThreadCell(thread: PreviewHelper.sampleThread,
                   contextUser: PreviewHelper.sampleUser,
                   contextMailboxManager: PreviewHelper.sampleMailboxManager,
                   density: .compact,
                   accentColor: .blue,
                   isMultipleSelectionEnabled: false,
                   isSelected: false)
    }
    .listStyle(.plain)
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
