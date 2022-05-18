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
    @StateRealmObject var message: Message
    @Binding var isExpanded: Bool
    @EnvironmentObject var card: MessageCard

    var body: some View {
        HStack(alignment: .top) {
            if let recipient = message.from.first {
                RecipientImage(recipient: recipient)
                    .onTapGesture {
                        openContact(recipient: recipient)
                    }
            }

            VStack(alignment: .leading, spacing: 0) {
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
                    ChevronButton(isExpanded: $isExpanded)
                }

                if isExpanded {
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
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openContact(recipient: Recipient) {
        card.state = .contact(recipient)
    }
}

struct MessageHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageHeaderView(message: PreviewHelper.sampleMessage, isExpanded: .constant(false))
            MessageHeaderView(message: PreviewHelper.sampleMessage, isExpanded: .constant(true))
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
