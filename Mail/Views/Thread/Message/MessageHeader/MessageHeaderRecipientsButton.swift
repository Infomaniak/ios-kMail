/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftUI

struct MessageHeaderRecipientsButton: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager

    @Binding var isHeaderExpanded: Bool

    let recipients: [Recipient]

    private var formattedRecipients: [String] {
        recipients.map {
            let contactConfiguration = ContactConfiguration.correspondent(
                correspondent: $0,
                contextMailboxManager: mailboxManager
            )
            let contact = CommonContactCache
                .getOrCreateContact(contactConfiguration: contactConfiguration)
            return contact.formatted()
        }
    }

    var body: some View {
        Button {
            matomo.track(eventWithCategory: .message, name: "openDetails", value: isHeaderExpanded)
            withAnimation {
                isHeaderExpanded.toggle()
            }
        } label: {
            HStack {
                Text(formattedRecipients, format: .list(type: .and))
                ChevronIcon(direction: isHeaderExpanded ? .up : .down)
            }
        }
    }
}

#Preview("Header Expanded") {
    MessageHeaderRecipientsButton(isHeaderExpanded: .constant(true), recipients: [PreviewHelper.sampleRecipient1])
        .environmentObject(PreviewHelper.sampleMailboxManager)
}

#Preview("Header Collapsed") {
    MessageHeaderRecipientsButton(isHeaderExpanded: .constant(false), recipients: [PreviewHelper.sampleRecipient1])
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
