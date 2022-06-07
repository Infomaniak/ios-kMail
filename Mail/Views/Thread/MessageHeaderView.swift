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

struct MessageHeaderView: View {
    @ObservedRealmObject var message: Message
    @Binding var isHeaderExpanded: Bool
    @Binding var isMessageExpanded: Bool
    let showActionButtons: Bool

    @EnvironmentObject var mailboxManager: MailboxManager
    @EnvironmentObject var sheet: MessageSheet
    @EnvironmentObject var card: MessageCard

    var body: some View {
        if message.isDraft {
            HStack(alignment: .top) {
                if let recipient = message.from.first {
                    RecipientImage(recipient: recipient)
                        .onTapGesture {
                            openContact(recipient: recipient)
                        }
                }
                Button {
                    editDraft(from: message)
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(MailResourcesStrings.messageIsDraftOption)
                                .foregroundColor(MailResourcesAsset.destructiveActionColor)
                                .textStyle(.header3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button {
                                deleteDraft(from: message)
                            } label: {
                                Image(resource: MailResourcesAsset.bin)
                            }
                        }
                        .tint(MailResourcesAsset.destructiveActionColor)

                        Text("Lorem ipsum dolor sit amet" /* message.preview */ )
                            .textStyle(.bodySecondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
        } else {
            if isMessageExpanded {
                HStack(alignment: .top) {
                    if let recipient = message.from.first {
                        RecipientImage(recipient: recipient)
                            .onTapGesture {
                                openContact(recipient: recipient)
                            }
                    }
                    Button {
                        isMessageExpanded.toggle()
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            MessageHeaderTitleView(message: message, isMessageExpanded: isMessageExpanded, isHeaderExpanded: $isHeaderExpanded)
                            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit." /* message.preview */ )
                                .textStyle(.bodySecondary)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
            } else {
                HStack(alignment: .top) {
                    if let recipient = message.from.first {
                        RecipientImage(recipient: recipient)
                            .onTapGesture {
                                openContact(recipient: recipient)
                            }
                    }
                    Button {
                        isMessageExpanded.toggle()
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            MessageHeaderTitleView(message: message, isMessageExpanded: isMessageExpanded, isHeaderExpanded: $isHeaderExpanded)

                            if isHeaderExpanded {
                                if let email = message.from.first?.email {
                                    Text(email)
                                        .textStyle(.callout)
                                }

                                VStack(alignment: .leading) {
                                    RecipientLabel(title: MailResourcesStrings.toTitle, recipients: message.to)
                                    if !message.cc.isEmpty {
                                        RecipientLabel(title: MailResourcesStrings.ccTitle, recipients: message.cc)
                                    }
                                    if !message.bcc.isEmpty {
                                        RecipientLabel(title: MailResourcesStrings.bccTitle, recipients: message.bcc)
                                    }
                                }
                                .textStyle(.calloutSecondary)
                                .padding(.top, 6)
                            } else {
                                Text(message.recipients.map(\.title), format: .list(type: .and))
                                    .lineLimit(1)
                                    .textStyle(.calloutSecondary)
                            }
                        }
                    }
                    .padding(.top, 2)

                    if showActionButtons {
                        HStack(spacing: 24) {
                            Button {
                                sheet.state = .reply(message, .reply)
                            } label: {
                                Image(resource: MailResourcesAsset.reply)
                                    .frame(width: 20, height: 20)
                            }
                            Button {
                                // TODO: Show menu
                            } label: {
                                Image(resource: MailResourcesAsset.plusActions)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .tint(MailResourcesAsset.infomaniakColor)
                        .padding(.top, 2)
                        .padding(.leading, 16)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func openContact(recipient: Recipient) {
        card.state = .contact(recipient)
    }

    private func editDraft(from message: Message) {
        var sheetPresented = false

        // If we already have the draft locally, present it directly
        if let draft = mailboxManager.draft(messageUid: message.uid)?.detached() {
            sheet.state = .edit(draft)
            sheetPresented = true
        }

        // Update the draft
        Task { [sheetPresented] in
            let draft = try await mailboxManager.draft(from: message)
            if !sheetPresented {
                sheet.state = .edit(draft)
            }
        }
    }

    private func deleteDraft(from: Message) {
        Task {
            try await mailboxManager.deleteDraft(from: message)
        }
    }
}

struct MessageHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageHeaderView(
                message: PreviewHelper.sampleMessage,
                isHeaderExpanded: .constant(false),
                isMessageExpanded: .constant(false),
                showActionButtons: true
            )
            MessageHeaderView(
                message: PreviewHelper.sampleMessage,
                isHeaderExpanded: .constant(true),
                isMessageExpanded: .constant(true),
                showActionButtons: true
            )
        }
    }
}

struct RecipientLabel: View {
    let title: String
    let recipients: RealmSwift.List<Recipient>

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(title)
            VStack(alignment: .leading) {
                ForEach(recipients, id: \.self) { recipient in
                    Text(text(for: recipient))
                }
            }
        }
    }

    private func text(for recipient: Recipient) -> String {
        if recipient.name.isEmpty {
            return recipient.email
        } else {
            return "\(recipient.name) (\(recipient.email))"
        }
    }
}

struct MessageHeaderTitleView: View {
    let message: Message
    let isMessageExpanded: Bool
    @Binding var isHeaderExpanded: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            ForEach(message.from, id: \.self) { recipient in
                Text(recipient.title)
                    .lineLimit(1)
                    .layoutPriority(1)
                    .textStyle(.header3)
            }
            Text(message.date, format: .dateTime)
                .lineLimit(1)
                .truncationMode(.middle)
                .textStyle(.calloutSecondary)
            Spacer()
            if !isMessageExpanded {
                ChevronButton(isExpanded: $isHeaderExpanded)
            }
        }
    }
}
