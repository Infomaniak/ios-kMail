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
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var mainViewState: MainViewState

    @ObservedRealmObject var message: Message

    @State private var replyOrReplyAllMessage: Message?
    @State private var contactViewRecipient: Recipient?

    @Binding var isMessageExpanded: Bool
    @Binding var isHeaderExpanded: Bool

    let deleteDraftTapped: () -> Void

    @LazyInjectService private var matomo: MatomoUtils

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(alignment: .center) {
                if let recipient = message.from.first {
                    Button {
                        matomo.track(eventWithCategory: .message, name: "selectAvatar")
                        contactViewRecipient = recipient
                    } label: {
                        AvatarView(
                            mailboxManager: mailboxManager,
                            contactBuilder: .recipient(recipient: recipient,
                                                       contextMailboxManager: mailboxManager),
                            size: 40
                        )
                    }
                    .adaptivePanel(item: $contactViewRecipient) { recipient in
                        ContactActionsView(recipient: recipient)
                    }
                }

                VStack(alignment: .leading, spacing: UIPadding.verySmall) {
                    if message.isDraft {
                        Text(MailResourcesStrings.Localizable.messageIsDraftOption)
                            .textStyle(.bodyMediumError)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: UIPadding.small) {
                            VStack {
                                ForEach(message.from) { recipient in
                                    let contactBuilder = CommonContactBuilder.recipient(
                                        recipient: recipient,
                                        contextMailboxManager: mailboxManager
                                    )
                                    let contact = CommonContactCache.getOrCreateContact(contactBuilder: contactBuilder)

                                    Text(contact,
                                         format: .displayablePerson())
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
                            Text(
                                message.recipients.map {
                                    let contactBuilder = CommonContactBuilder.recipient(
                                        recipient: $0,
                                        contextMailboxManager: mailboxManager
                                    )
                                    let contact = CommonContactCache.getOrCreateContact(contactBuilder: contactBuilder)
                                    return contact.formatted()
                                },
                                format: .list(type: .and)
                            )
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
                        IKIcon(size: .large, image: MailResourcesAsset.bin, shapeStyle: MailResourcesAsset.redColor.swiftUIColor)
                    }
                }
            }

            Spacer()

            if isMessageExpanded {
                HStack(spacing: 20) {
                    Button {
                        matomo.track(eventWithCategory: .messageActions, name: "reply")
                        if message.canReplyAll(currentMailboxEmail: mailboxManager.mailbox.email) {
                            replyOrReplyAllMessage = message
                        } else {
                            mainViewState.editedDraft = EditedDraft.replying(
                                reply: MessageReply(message: message, replyMode: .reply),
                                currentMailboxEmail: mailboxManager.mailbox.email
                            )
                        }
                    } label: {
                        IKIcon(size: .large, image: MailResourcesAsset.emailActionReply)
                    }
                    .adaptivePanel(item: $replyOrReplyAllMessage) { message in
                        ReplyActionsView(message: message)
                    }
                    ActionsPanelButton(messages: [message], originFolder: message.folder) {
                        IKIcon(size: .large, image: MailResourcesAsset.plusActions)
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
            }
            MessageHeaderSummaryView(message: PreviewHelper.sampleMessage,
                                     isMessageExpanded: .constant(true),
                                     isHeaderExpanded: .constant(false)) {
                // Preview
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
