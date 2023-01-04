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
import RealmSwift
import SwiftUI

struct MessageHeaderSummaryView: View {
    @ObservedRealmObject var message: Message
    @Binding var isMessageExpanded: Bool
    @Binding var isHeaderExpanded: Bool
    let deleteDraftTapped: () -> Void
    let replyButtonTapped: () -> Void
    let moreButtonTapped: () -> Void
    let recipientTapped: (Recipient) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(alignment: .center) {
                if let recipient = message.from.first {
                    Button {
                        recipientTapped(recipient)
                    } label: {
                        RecipientImage(recipient: recipient, size: 40)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if message.isDraft {
                        HStack {
                            Text(MailResourcesStrings.Localizable.messageIsDraftOption)
                                .textStyle(.bodyMediumError)
                            Spacer()
                            Button(action: deleteDraftTapped) {
                                Image(resource: MailResourcesAsset.bin)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .tint(MailResourcesAsset.redActionColor)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            VStack {
                                ForEach(message.from, id: \.self) { recipient in
                                    Text(recipient.title)
                                        .lineLimit(1)
                                        .textStyle(.bodyMedium)
                                }
                            }
                            Text(message.date.customRelativeFormatted)
                                .lineLimit(1)
                                .layoutPriority(1)
                                .textStyle(.captionSecondary)
                        }
                    }

                    if isMessageExpanded {
                        HStack {
                            Text(message.recipients.map(\.title), format: .list(type: .and))
                                .lineLimit(1)
                                .textStyle(.bodySmallSecondary)
                            ChevronButton(isExpanded: $isHeaderExpanded)
                        }
                    } else {
                        Text(message.formattedSubject)
                            .textStyle(.bodySecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if isMessageExpanded {
                HStack(spacing: 20) {
                    Button(action: replyButtonTapped) {
                        Image(resource: MailResourcesAsset.emailActionReply)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    Button(action: moreButtonTapped) {
                        Image(resource: MailResourcesAsset.plusActions)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
                .padding(.leading, 8)
            }
        }
    }
}

struct MessageHeaderSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageHeaderSummaryView(message: PreviewHelper.sampleMessage,
                                     isMessageExpanded: .constant(false),
                                     isHeaderExpanded: .constant(false)) {
                // Preview
            } replyButtonTapped: {
                // Preview
            } moreButtonTapped: {
                // Preview
            } recipientTapped: { _ in
                // Preview
            }
            MessageHeaderSummaryView(message: PreviewHelper.sampleMessage,
                                     isMessageExpanded: .constant(true),
                                     isHeaderExpanded: .constant(false)) {
                // Preview
            } replyButtonTapped: {
                // Preview
            } moreButtonTapped: {
                // Preview
            } recipientTapped: { _ in
                // Preview
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
