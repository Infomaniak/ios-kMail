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

import InfomaniakCore
import InfomaniakDI
import MailCore
import MailCoreUI
import RealmSwift
import SwiftUI

struct MessageSubHeaderView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ObservedRealmObject var message: Message

    @Binding var displayContentBlockedActionView: Bool

    var body: some View {
        MessageBannerHeaderView(
            message: message,
            mailbox: mailboxManager.mailbox,
            displayContentBlockedActionView: $displayContentBlockedActionView
        )

        if let event = message.calendarEventResponse?.frozenEvent, event.type == .event {
            CalendarView(event: event)
                .padding(.horizontal, value: .medium)
        }

        if !message.notInlineAttachments.isEmpty
            || message.swissTransferUuid != nil {
            AttachmentsView(message: message, attachments: Array(message.notInlineAttachments))
        }
    }
}

#Preview {
    MessageSubHeaderView(message: PreviewHelper.sampleMessage, displayContentBlockedActionView: .constant(false))
}
