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
    let thread: Thread
    let mailboxManager: MailboxManager

    /// Sender of the last message that is not in the Sent folder, otherwise the last message of the thread
    var recipientToDisplay: Recipient? {
        let sentFolderId = mailboxManager.getFolder(with: .sent)?.id
        let lastMessageNotFromSent = thread.messages.last { $0.folderId != sentFolderId } ?? thread.messages.last
        return lastMessageNotFromSent?.from.last
    }

    /// Date of the last message of the folder, otherwise the last message of the thread
    var date: String {
        return thread.date.customRelativeFormatted
    }

    /// Field `to` in the draft folder, otherwise field `from`
    var from: String {
        let isDraftFolder = thread.messages.allSatisfy(\.isDraft)
        return isDraftFolder ? thread.formattedTo : thread.formattedFrom
    }

    /// Subject of the first message
    var subject: String {
        thread.formattedSubject
    }

    /// Last message of the thread, except for the Sent folder where we use the last message of the folder
    var preview: String {
        var content = thread.messages.last?.preview
        if thread.folderId == mailboxManager.getFolder(with: .sent)?.id {
            content = (thread.lastMessageFromFolder ?? thread.messages.last)?.preview
        }

        guard let content, !content.isEmpty else {
            return MailResourcesStrings.Localizable.noBodyTitle
        }
        return content
    }
}

struct ThreadCell: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = AccentColor.pink

    let thread: Thread
    let mailboxManager: MailboxManager

    let dataHolder: ThreadCellDataHolder

    let density: ThreadDensity
    let isMultipleSelectionEnabled: Bool
    let isSelected: Bool

    private var checkboxSize: CGFloat {
        density == .large ? Constants.checkboxLargeSize : Constants.checkboxSize
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
            unreadIndicator
                .animation(
                    .threadListSlide(density: density, isMultipleSelectionEnabled: isMultipleSelectionEnabled),
                    value: isMultipleSelectionEnabled
                )

            Group {
                if density == .large, let recipient = dataHolder.recipientToDisplay {
                    ZStack {
                        RecipientImage(recipient: recipient)
                        checkbox
                            .opacity(isSelected ? 1 : 0)
                    }
                } else if isMultipleSelectionEnabled {
                    checkbox
                        .animation(
                            .threadListCheckbox(isMultipleSelectionEnabled: isMultipleSelectionEnabled),
                            value: isMultipleSelectionEnabled
                        )
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
            .animation(
                .threadListSlide(density: density, isMultipleSelectionEnabled: isMultipleSelectionEnabled),
                value: isMultipleSelectionEnabled
            )
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, density.cellVerticalPadding)
        .clipped()
    }

    private var unreadIndicator: some View {
        Circle()
            .frame(width: Constants.unreadIconSize, height: Constants.unreadIconSize)
            .foregroundColor(thread.hasUnseenMessages ? Color.accentColor : .clear)
    }

    private var checkbox: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .background(Circle().fill(isSelected ? Color.accentColor : Color.clear))
                .frame(width: checkboxSize, height: checkboxSize)
            Image(resource: MailResourcesAsset.check)
                .foregroundColor(MailResourcesAsset.onAccentColor)
                .frame(height: Constants.checkmarkSize)
                .opacity(isSelected ? 1 : 0)
        }
    }

    private var cellHeader: some View {
        HStack(spacing: 8) {
            if thread.hasDrafts {
                Text("\(MailResourcesStrings.Localizable.draftPrefix)")
                    .textStyle(.header2Error)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            Text(dataHolder.from)
                .textStyle(.header2)
                .lineLimit(1)

            if thread.messages.count > 1 {
                Text("\(thread.messages.count)")
                    .textStyle(.bodySmallSecondary)
                    .padding(.horizontal, 4)
                    .lineLimit(1)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(MailResourcesAsset.snackbarTextColor.swiftUiColor)
                    }
            }

            Spacer()

            Text(dataHolder.date)
                .textStyle(.bodySmallSecondary)
                .lineLimit(1)
        }
    }

    private var threadInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dataHolder.subject)
                .textStyle(.body)
                .lineLimit(1)

            if density != .compact {
                Text(dataHolder.preview)
                    .textStyle(.bodySmallSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var threadDetails: some View {
        HStack(spacing: 8) {
            if thread.hasAttachments {
                Image(resource: MailResourcesAsset.attachment)
                    .resizable()
                    .foregroundColor(MailResourcesAsset.primaryTextColor)
                    .scaledToFit()
                    .frame(height: 16)
            }
            if thread.flagged {
                Image(resource: MailResourcesAsset.starFull)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
        }
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
