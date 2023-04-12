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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
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

    @LazyInjectService private var matomo: MatomoUtils

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(alignment: .center) {
                if let recipient = message.from.first {
                    Button {
                        matomo.track(eventWithCategory: .message, name: "selectAvatar")
                        recipientTapped(recipient)
                    } label: {
                        AvatarView(avatarDisplayable: recipient, size: 40)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if message.isDraft {
                        Text(MailResourcesStrings.Localizable.messageIsDraftOption)
                            .textStyle(.bodyMediumError)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            VStack {
                                ForEach(message.from, id: \.self) { recipient in
                                    Text(recipient.formattedName)
                                        .lineLimit(1)
                                        .textStyle(.bodyMedium)
                                }
                            }
                            Text(message.date.customRelativeFormatted)
                                .lineLimit(1)
                                .layoutPriority(1)
                                .textStyle(.labelSecondary)
                        }
                    }

                    if isMessageExpanded {
                        HStack {
                            Text(message.recipients.map(\.formattedName), format: .list(type: .and))
                                .lineLimit(1)
                                .textStyle(.bodySmallSecondary)
                            ChevronButton(isExpanded: $isHeaderExpanded)
                                .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonExpandRecipients)
                                .onChange(of: isHeaderExpanded) { isExpanded in
                                    matomo.track(eventWithCategory: .message, name: "openDetails", value: isExpanded)
                                }
                        }
                    } else {
                        Text(message.formattedSubject)
                            .textStyle(.bodySecondary)
                            .lineLimit(1)
                    }
                }

                if message.isDraft {
                    Spacer()
                    Button(action: deleteDraftTapped) {
                        MailResourcesAsset.bin.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                    .tint(MailResourcesAsset.redColor)
                }
            }

            Spacer()

            if isMessageExpanded {
                HStack(spacing: 20) {
                    Button(action: replyButtonTapped) {
                        MailResourcesAsset.emailActionReply.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    Button(action: moreButtonTapped) {
                        MailResourcesAsset.plusActions.swiftUIImage
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
