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
                            contactConfiguration: .correspondent(correspondent: recipient,
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
                                    let contactConfiguration = ContactConfiguration.correspondent(
                                        correspondent: recipient,
                                        contextMailboxManager: mailboxManager
                                    )
                                    let contact = CommonContactCache
                                        .getOrCreateContact(contactConfiguration: contactConfiguration)

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

                    Group {
                        if isMessageExpanded {
                            HStack {
                                Text(
                                    message.recipients.map {
                                        let contactConfiguration = ContactConfiguration.correspondent(
                                            correspondent: $0,
                                            contextMailboxManager: mailboxManager
                                        )
                                        let contact = CommonContactCache
                                            .getOrCreateContact(contactConfiguration: contactConfiguration)
                                        return contact.formatted()
                                    },
                                    format: .list(type: .and)
                                )

                                ChevronButton(isExpanded: $isHeaderExpanded)
                                    .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionButtonExpandRecipients)
                                    .onChange(of: isHeaderExpanded) { isExpanded in
                                        matomo.track(eventWithCategory: .message, name: "openDetails", value: isExpanded)
                                    }
                            }
                        } else {
                            Text(message.formattedSubject)
                        }
                    }
                    .textStyle(.bodySmallSecondary)
                    .lineLimit(1)
                }

                if message.isDraft {
                    Spacer()
                    Button(role: .destructive, action: deleteDraftTapped) {
                        IKIcon(MailResourcesAsset.bin, size: .large)
                    }
                    .foregroundStyle(MailResourcesAsset.redColor)
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
                            mainViewState.composeMessageIntent = .replyingTo(
                                message: message,
                                replyMode: .reply,
                                originMailboxManager: mailboxManager
                            )
                        }
                    } label: {
                        IKIcon(MailResourcesAsset.emailActionReply, size: .large)
                    }
                    .adaptivePanel(item: $replyOrReplyAllMessage) { message in
                        ReplyActionsView(message: message)
                    }
                    ActionsPanelButton(messages: [message], originFolder: message.folder, panelSource: .messageList) {
                        IKIcon(MailResourcesAsset.plusActions, size: .large)
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
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .previewLayout(.sizeThatFits)
    }
}
