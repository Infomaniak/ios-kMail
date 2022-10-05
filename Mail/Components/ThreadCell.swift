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
        self == .compact ? 8 : 16
    }
}

struct ThreadCell: View {
    @AppStorage(UserDefaults.shared.key(.threadDensity)) var density: ThreadDensity = .normal
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = AccentColor.pink

    @State private var shouldNavigateToThreadList = false

    var thread: Thread

    var isMultipleSelectionEnabled: Bool = false
    var isSelected: Bool = false

    private var textStyle: MailTextStyle {
        thread.hasUnseenMessages ? .header3 : .bodySecondary
    }

    private var checkboxSize: CGFloat {
        density == .compact ? Constants.checkboxCompactSize : Constants.checkboxSize
    }
    private var checkmarkSize: CGFloat {
        density == .compact ? Constants.checkmarkCompactSize : Constants.checkmarkSize
    }

    // MARK: - Views

    var body: some View {
        HStack(spacing: 8) {
            unreadIndicator
                .animation(.threadListSlide(density: density, isMultipleSelectionEnabled: isMultipleSelectionEnabled),
                           value: isMultipleSelectionEnabled)

            Group {
                if density == .large, let recipient = thread.from.last {
                    ZStack {
                        RecipientImage(recipient: recipient, size: 32)
                        checkbox
                            .opacity(isSelected ? 1 : 0)
                    }
                } else if isMultipleSelectionEnabled {
                    checkbox
                        .animation(.threadListCheckbox(isMultipleSelectionEnabled: isMultipleSelectionEnabled),
                                   value: isMultipleSelectionEnabled)
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
            .animation(.threadListSlide(density: density, isMultipleSelectionEnabled: isMultipleSelectionEnabled),
                       value: isMultipleSelectionEnabled)
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
                .foregroundColor(.white)
                .frame(height: checkmarkSize)
                .opacity(isSelected ? 1 : 0)
        }
    }

    private var cellHeader: some View {
        HStack(spacing: 8) {
            if thread.hasDrafts {
                Text("(\(MailResourcesStrings.Localizable.messageIsDraftOption))")
                    .foregroundColor(MailResourcesAsset.redActionColor)
                    .textStyle(thread.hasUnseenMessages ? .header2 : .header2Secondary)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            Text(thread.messages.allSatisfy(\.isDraft) ? thread.formattedTo : thread.formattedFrom)
                .textStyle(thread.hasUnseenMessages ? .header2 : .header2Secondary)
                .lineLimit(1)

            if thread.uniqueMessagesCount > 1 {
                Text("\(thread.uniqueMessagesCount)")
                    .textStyle(.bodySecondary)
                    .padding(.horizontal, 4)
                    .lineLimit(1)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(MailResourcesAsset.snackbarTextColor.swiftUiColor)
                    }
            }

            Spacer()

            if thread.hasAttachments {
                Image(resource: MailResourcesAsset.attachmentMail1)
                    .resizable()
                    .foregroundColor(textStyle.color)
                    .scaledToFit()
                    .frame(width: 16)
            }

            Text(thread.date.customRelativeFormatted)
                .textStyle(thread.hasUnseenMessages ? .calloutStrong : .calloutSecondary)
                .lineLimit(1)
        }
    }

    private var threadInfo: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(thread.formattedSubject)
                .textStyle(textStyle)
                .lineLimit(1)

            if density != .compact,
               let preview = thread.messages.last?.preview,
               !preview.isEmpty {
                Text(preview)
                    .textStyle(thread.hasUnseenMessages ? .body : .bodySecondary)
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
                    .frame(width: 16, height: 16)
            }
        }
    }
}

struct ThreadCell_Previews: PreviewProvider {
    static var previews: some View {
        ThreadCell(thread: PreviewHelper.sampleThread,
                       isMultipleSelectionEnabled: false,
                       isSelected: false)
            .previewLayout(.sizeThatFits)
            .previewDevice("iPhone 13 Pro")
    }
}
