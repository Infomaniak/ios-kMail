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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct MessageHeaderSummaryView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.isMessageInteractive) private var isMessageInteractive
    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var mainViewState: MainViewState

    @ObservedRealmObject var message: Message

    @State private var replyOrReplyAllMessage: Message?
    @State private var contactViewRecipient: Recipient?

    @Binding var isMessageExpanded: Bool
    @Binding var isHeaderExpanded: Bool

    let deleteDraftTapped: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(alignment: .center) {
                if let recipient = message.from.first {
                    Button {
                        didTapAvatar(of: recipient)
                    } label: {
                        AvatarView(
                            mailboxManager: mailboxManager,
                            contactConfiguration: .correspondent(correspondent: recipient,
                                                                 associatedBimi: message.bimi,
                                                                 contextUser: currentUser.value,
                                                                 contextMailboxManager: mailboxManager),
                            size: 40
                        )
                    }
                    .adaptivePanel(item: $contactViewRecipient) { recipient in
                        ContactActionsView(recipient: recipient, bimi: message.bimi)
                            .environmentObject(mailboxManager)
                            .environment(\.currentUser, currentUser)
                        // We need to manually pass environment and environmentObject because of a bug with SwiftUI end popovers
                        // on macOS
                    }
                    .disabled(!isMessageInteractive)
                }

                VStack(alignment: .leading, spacing: IKPadding.micro) {
                    if message.isDraft {
                        Text(MailResourcesStrings.Localizable.messageIsDraftOption)
                            .textStyle(.bodyMediumError)
                    } else {
                        HStack(spacing: IKPadding.mini) {
                            HStack(spacing: IKPadding.micro) {
                                VStack {
                                    ForEach(message.from) { recipient in
                                        Text(contact(for: recipient), format: .displayablePerson())
                                            .lineLimit(1)
                                            .textStyle(.bodyMedium)
                                    }
                                }

                                if let bimi = message.bimi, bimi.shouldDisplayBimi {
                                    MailResourcesAsset.checkmarkAuthentication
                                        .iconSize(.small)
                                }
                            }

                            HeaderDateView(displayDate: message.displayDate, format: .header)
                        }
                        .accessibilityElement(children: .combine)
                    }

                    Group {
                        if isMessageExpanded {
                            MessageHeaderRecipientsButton(isHeaderExpanded: $isHeaderExpanded, recipients: message.recipients)
                        } else {
                            Text(message.formattedSubject)
                        }
                    }
                    .textStyle(.bodySmallSecondary)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isButton)
                }
                .accessibilityHint(MailResourcesStrings.Localizable.contentDescriptionButtonExpandRecipients)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if message.isDraft {
                Button(role: .destructive, action: deleteDraftTapped) {
                    MailResourcesAsset.bin
                        .iconSize(.large)
                }
                .foregroundStyle(MailResourcesAsset.redColor)
            }

            if isMessageExpanded && isMessageInteractive && !(message.isScheduledDraft ?? false) {
                HStack(spacing: IKPadding.medium) {
                    Button(action: replyToMessage) {
                        MailResourcesAsset.emailActionReply
                            .iconSize(.large)
                    }
                    .adaptivePanel(item: $replyOrReplyAllMessage) { message in
                        ReplyActionsView(message: message)
                    }

                    ActionsPanelButton(messages: [message], originFolder: message.folder, panelSource: .message) {
                        MailResourcesAsset.plusActions
                            .iconSize(.large)
                    }
                }
                .padding(.leading, value: .mini)
            }
        }
    }

    private func didTapAvatar(of recipient: Recipient) {
        matomo.track(eventWithCategory: .message, name: "selectAvatar")
        contactViewRecipient = recipient
    }

    private func replyToMessage() {
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
    }

    private func contact(for recipient: Recipient) -> CommonContact {
        let contactConfiguration = ContactConfiguration.correspondent(
            correspondent: recipient,
            contextUser: currentUser.value,
            contextMailboxManager: mailboxManager
        )
        let contact = CommonContactCache.getOrCreateContact(contactConfiguration: contactConfiguration)

        return contact
    }
}

@available(iOS 17.0, *)
#Preview("Message collapsed", traits: .sizeThatFitsLayout) {
    MessageHeaderSummaryView(
        message: PreviewHelper.sampleMessage,
        isMessageExpanded: .constant(false),
        isHeaderExpanded: .constant(false)
    ) {}
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}

@available(iOS 17.0, *)
#Preview("Message expanded", traits: .sizeThatFitsLayout) {
    MessageHeaderSummaryView(
        message: PreviewHelper.sampleMessage,
        isMessageExpanded: .constant(true),
        isHeaderExpanded: .constant(false)
    ) {}
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
