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

struct ThreadCellConfiguration {
    private let thread: Thread

    ///
    var avatar: Recipient? {
        let lastMessageNotFromSent = thread.messages.last { $0.folderId != "SENT" } ?? thread.messages.last
        return lastMessageNotFromSent?.from.last
    }

    ///
    var date: Date {
        return thread.date
    }

    ///
    var from: String {
        let isDraftFolder = thread.messages.allSatisfy(\.isDraft)
        return isDraftFolder ? thread.formattedTo : thread.formattedFrom
    }
    ///
    var subject: String {
        thread.formattedSubject
    }
    ///
    var preview: String {
        var preview = thread.messages.last?.preview
        if thread.folderId == "SENT" {
            preview = thread.lastMessageFromThread?.preview ?? thread.messages.last?.preview
        }

        guard let preview, !preview.isEmpty else {
            return MailResourcesStrings.Localizable.noBodyTitle
        }
        return preview
    }

    init(thread: Thread) {
        self.thread = thread
    }
}

struct ThreadCell: View {
    let thread: Thread

    let threadCellConfiguration: ThreadCellConfiguration

    let threadDensity: ThreadDensity
    let accentColor: AccentColor

    let isMultipleSelectionEnabled: Bool
    let isSelected: Bool

    private var checkboxSize: CGFloat {
        threadDensity == .large ? Constants.checkboxLargeSize : Constants.checkboxSize
    }

    init(thread: Thread, threadDensity: ThreadDensity, accentColor: AccentColor, isMultipleSelectionEnabled: Bool = false, isSelected: Bool = false) {
        self.thread = thread

        self.threadCellConfiguration = ThreadCellConfiguration(thread: thread)

        self.threadDensity = threadDensity
        self.accentColor = accentColor

        self.isMultipleSelectionEnabled = isMultipleSelectionEnabled
        self.isSelected = isSelected
    }

    // MARK: - Views

    var body: some View {
        HStack(spacing: 8) {
            unreadIndicator
                .animation(
                    .threadListSlide(density: threadDensity, isMultipleSelectionEnabled: isMultipleSelectionEnabled),
                    value: isMultipleSelectionEnabled
                )

            Group {
                if threadDensity == .large, let recipient = threadCellConfiguration.avatar {
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
                .threadListSlide(density: threadDensity, isMultipleSelectionEnabled: isMultipleSelectionEnabled),
                value: isMultipleSelectionEnabled
            )
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, threadDensity.cellVerticalPadding)
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
                    .textStyle(.bodyError)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            Text(threadCellConfiguration.from)
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

            Text(threadCellConfiguration.date.customRelativeFormatted)
                .textStyle(.bodySmallSecondary)
                .lineLimit(1)
        }
    }

    private var threadInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(threadCellConfiguration.subject)
                .textStyle(.body)
                .lineLimit(1)

            if threadDensity != .compact {
                Text(threadCellConfiguration.preview)
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
                   threadDensity: .large,
                   accentColor: .pink,
                   isMultipleSelectionEnabled: false,
                   isSelected: false)
            .previewLayout(.sizeThatFits)
            .previewDevice("iPhone 13 Pro")
    }
}
