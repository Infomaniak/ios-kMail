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

    init(thread: Thread) {
        let lastMessageNotFromSent = thread.messages.last { $0.folder?.role != .sent } ?? thread.messages.last
        recipientToDisplay = lastMessageNotFromSent?.from.last

        date = thread.date.customRelativeFormatted

        subject = thread.formattedSubject

        var content = thread.messages.last?.preview
        if thread.folder?.role == .sent {
            content = (thread.lastMessageFromFolder ?? thread.messages.last)?.preview
        }

        if let content, !content.isEmpty {
            preview = content
        } else {
            preview = MailResourcesStrings.Localizable.noBodyTitle
        }
    }
}

struct ThreadCell: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    /// With normal or compact density, the checkbox should appear and disappear at different times of the cell offset.
    @State private var shouldDisplayCheckbox = false

    let thread: Thread

    let dataHolder: ThreadCellDataHolder

    let density: ThreadDensity
    let isMultipleSelectionEnabled: Bool
    let isSelected: Bool

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

    init(thread: Thread, density: ThreadDensity, isMultipleSelectionEnabled: Bool = false, isSelected: Bool = false) {
        self.thread = thread

        dataHolder = ThreadCellDataHolder(thread: thread)

        self.density = density
        self.isMultipleSelectionEnabled = isMultipleSelectionEnabled
        self.isSelected = isSelected
    }

    // MARK: - Views

    var body: some View {
        HStack(spacing: 8) {
            UnreadIndicatorView(hidden: !thread.hasUnseenMessages)
                .accessibilityLabel(additionalAccessibilityLabel)
                .accessibilityHidden(additionalAccessibilityLabel.isEmpty)

            Group {
                if density == .large, let recipient = dataHolder.recipientToDisplay {
                    ZStack {
                        AvatarView(
                            displayablePerson: DisplayablePerson(recipient: recipient, contextMailboxManager: mailboxManager),
                            size: 40
                        )
                        .opacity(isSelected ? 0 : 1)
                        CheckboxView(isSelected: isSelected, density: density)
                            .opacity(isSelected ? 1 : 0)
                    }
                    .accessibility(hidden: true)
                    .animation(nil, value: isSelected)
                } else if isMultipleSelectionEnabled {
                    CheckboxView(isSelected: isSelected, density: density)
                        .opacity(shouldDisplayCheckbox ? 1 : 0)
                        .animation(.default.speed(1.5), value: shouldDisplayCheckbox)
                }
            }
            .padding(.trailing, 4)

            VStack(alignment: .leading, spacing: 4) {
                ThreadCellHeaderView(thread: thread)

                HStack(alignment: .top, spacing: 3) {
                    ThreadCellInfoView(dataHolder: dataHolder, density: density)
                    Spacer()
                    ThreadCellDetailsView(thread: thread)
                }
            }
            .animation(
                isMultipleSelectionEnabled ? .threadListSlide : .threadListSlide.delay(UIConstants.checkboxDisappearOffsetDelay),
                value: isMultipleSelectionEnabled
            )
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, density.cellVerticalPadding)
        .clipped()
        .accessibilityElement(children: .combine)
        .onChange(of: isMultipleSelectionEnabled) { isEnabled in
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
}

struct ThreadCell_Previews: PreviewProvider {
    static var previews: some View {
        ThreadCell(thread: PreviewHelper.sampleThread,
                   density: .large,
                   isMultipleSelectionEnabled: false,
                   isSelected: false)
            .previewLayout(.sizeThatFits)
            .previewDevice("iPhone 13 Pro")
    }
}
