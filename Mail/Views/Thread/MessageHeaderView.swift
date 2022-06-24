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
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct MessageHeaderView: View {
    @ObservedRealmObject var message: Message
    @Binding var isHeaderExpanded: Bool
    @Binding var isMessageExpanded: Bool

    @EnvironmentObject var mailboxManager: MailboxManager
    @EnvironmentObject var sheet: MessageSheet
    @EnvironmentObject var bottomSheet: MessageBottomSheet
    @EnvironmentObject var threadBottomSheet: ThreadBottomSheet

    var body: some View {
        HStack(alignment: message.isDraft ? .center : .top) {
            if let recipient = message.from.first {
                RecipientImage(recipient: recipient)
                    .onTapGesture {
                        openContact(recipient: recipient)
                    }
            }

            VStack(alignment: .leading, spacing: 0) {
                if message.isDraft {
                    HStack {
                        Text(MailResourcesStrings.messageIsDraftOption)
                            .foregroundColor(MailResourcesAsset.redActionColor)
                            .textStyle(.header3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button {
                            deleteDraft(from: message)
                        } label: {
                            Image(resource: MailResourcesAsset.bin)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                        }
                    }
                    .tint(MailResourcesAsset.redActionColor)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        ForEach(message.from, id: \.self) { recipient in
                            Text(recipient.title)
                                .lineLimit(1)
                                .textStyle(.header3)
                        }
                        Text(message.date.customRelativeFormatted)
                            .lineLimit(1)
                            .layoutPriority(1)
                            .textStyle(.calloutSecondary)
                        Spacer()
                        if isMessageExpanded {
                            ChevronButton(isExpanded: $isHeaderExpanded)
                        }
                    }
                }

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
                } else if isMessageExpanded {
                    Text(message.recipients.map(\.title), format: .list(type: .and))
                        .lineLimit(1)
                        .textStyle(.calloutSecondary)
                } else {
                    Text(message.preview)
                        .textStyle(.bodySecondary)
                        .lineLimit(1)
                }
            }
            .padding(.top, 2)

            if isMessageExpanded {
                HStack(spacing: 24) {
                    Button {
                        sheet.state = .reply(message, .reply)
                    } label: {
                        Image(resource: MailResourcesAsset.emailActionReply)
                            .frame(width: 20, height: 20)
                    }
                    Button {
                        threadBottomSheet.open(state: .actions(.message(message.thaw() ?? message)), position: .middle)
                    } label: {
                        Image(resource: MailResourcesAsset.plusActions)
                            .frame(width: 20, height: 20)
                    }
                }
                .padding(.top, 2)
                .padding(.leading, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture {
            if message.isDraft {
                editDraft(from: message)
            } else if !isMessageExpanded {
                withAnimation {
                    isMessageExpanded = true
                }
            }
        }
    }

    private func openContact(recipient: Recipient) {
        bottomSheet.open(state: .contact(recipient), position: .top)
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
            await tryOrDisplayError {
                try await mailboxManager.deleteDraft(from: message)
            }
        }
    }
}

struct MessageHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        MessageHeaderView(
            message: PreviewHelper.sampleMessage,
            isHeaderExpanded: .constant(false),
            isMessageExpanded: .constant(false)
        )
        MessageHeaderView(
            message: PreviewHelper.sampleMessage,
            isHeaderExpanded: .constant(false),
            isMessageExpanded: .constant(true)
        )
        MessageHeaderView(
            message: PreviewHelper.sampleMessage,
            isHeaderExpanded: .constant(true),
            isMessageExpanded: .constant(true)
        )
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
                    Text(text(for: recipient)).multilineTextAlignment(.leading)
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
