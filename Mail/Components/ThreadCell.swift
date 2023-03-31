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
    static func threadListCheckbox(isMultipleSelectionEnabled isEnabled: Bool) -> Animation {
        .default.delay(isEnabled ? 0.5 : 0)
    }

    static func threadListSlide(density: ThreadDensity, isMultipleSelectionEnabled isEnabled: Bool) -> Animation {
        if density == .large {
            return .default
        }
        return .default.speed(2).delay(isEnabled ? 0 : 0.22)
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

    /// Field `to` in the draft folder, otherwise field `from`
    let from: String

    /// Subject of the first message
    let subject: String

    /// Last message of the thread, except for the Sent folder where we use the last message of the folder
    let preview: String

    init(thread: Thread, mailboxManager: MailboxManager) {
        let lastMessageNotFromSent = thread.messages.last { $0.folder?.role != .sent } ?? thread.messages.last
        recipientToDisplay = lastMessageNotFromSent?.from.last

        date = thread.date.customRelativeFormatted

        let isDraftFolder = thread.messages.allSatisfy(\.isDraft)
        from = isDraftFolder ? thread.formattedTo : thread.formattedFrom

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
    let thread: Thread
    let mailboxManager: MailboxManager

    let dataHolder: ThreadCellDataHolder

    let density: ThreadDensity
    let isMultipleSelectionEnabled: Bool
    let isSelected: Bool

    private var checkboxSize: CGFloat {
        density == .large ? UIConstants.checkboxLargeSize : UIConstants.checkboxSize
    }

    init(
        thread: Thread,
        mailboxManager: MailboxManager,
        density: ThreadDensity,
        isMultipleSelectionEnabled: Bool = false,
        isSelected: Bool = false
    ) {
        self.thread = thread
        self.mailboxManager = mailboxManager

        dataHolder = ThreadCellDataHolder(thread: thread, mailboxManager: mailboxManager)

        self.density = density
        self.isMultipleSelectionEnabled = isMultipleSelectionEnabled
        self.isSelected = isSelected
    }

    // MARK: - Views

    var body: some View {
        HStack(spacing: 8) {
            UnreadIndicatorView(hidden: !thread.hasUnseenMessages)
                .animation(
                    .threadListSlide(density: density, isMultipleSelectionEnabled: isMultipleSelectionEnabled),
                    value: isMultipleSelectionEnabled
                )

            Group {
                if density == .large, let recipient = dataHolder.recipientToDisplay {
                    ZStack {
                        AvatarView(avatarDisplayable: recipient, size: 40)
                        CheckboxView(isSelected: isSelected, density: density)
                            .opacity(isSelected ? 1 : 0)
                    }
                } else if isMultipleSelectionEnabled {
                    CheckboxView(isSelected: isSelected, density: density)
                        .animation(
                            .threadListCheckbox(isMultipleSelectionEnabled: isMultipleSelectionEnabled),
                            value: isMultipleSelectionEnabled
                        )
                }
            }
            .padding(.trailing, 4)

            VStack(alignment: .leading, spacing: 4) {
                ThreadCellHeaderView(thread: thread, dataHolder: dataHolder)

                HStack(alignment: .top, spacing: 3) {
                    ThreadCellInfoView(dataHolder: dataHolder, density: density)
                    Spacer()
                    ThreadCellDetailsView(thread: thread)
                }
            }
            .animation(
                .threadListSlide(density: density, isMultipleSelectionEnabled: isMultipleSelectionEnabled),
                value: isMultipleSelectionEnabled
            )
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, density.cellVerticalPadding)
        .clipped()
    }
}

struct ThreadCell_Previews: PreviewProvider {
    static var previews: some View {
        ThreadCell(thread: PreviewHelper.sampleThread,
                   mailboxManager: PreviewHelper.sampleMailboxManager,
                   density: .large,
                   isMultipleSelectionEnabled: false,
                   isSelected: false)
            .previewLayout(.sizeThatFits)
            .previewDevice("iPhone 13 Pro")
    }
}
