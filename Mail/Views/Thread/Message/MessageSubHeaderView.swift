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
    @Environment(\.isMessageInteractive) private var isMessageInteractive

    @EnvironmentObject private var mailboxManager: MailboxManager

    @ObservedRealmObject var message: Message

    @Binding var displayContentBlockedActionView: Bool

    private var banners: [MessageBanner] {
        var result = [MessageBanner]()

        if let isScheduledDraft = message.isScheduledDraft,
           isScheduledDraft,
           let scheduleDate = message.scheduleDate,
           let draftResource = message.draftResource {
            result.append(.schedule(scheduleDate: scheduleDate, draftResource: draftResource))
        }

        if let spamType = spamTypeFor(message: message) {
            result.append(.spam(spamType: spamType))
        }

        if message.hasUnsubscribeLink == true {
            result.append(.unsubscribeLink)
        }

        if isRemoteContentBlocked && displayContentBlockedActionView {
            result.append(.displayContent)
        }

        if message.encrypted {
            result.append(.encrypted)
        }

        if message.hasPendingAcknowledgment {
            result.append(.acknowledge)
        }

        return result
    }

    private var isRemoteContentBlocked: Bool {
        return (UserDefaults.shared.displayExternalContent == .askMe || message.folder?.role == .spam)
            && !message.localSafeDisplay
    }

    var body: some View {
        if isMessageInteractive {
            MessageBannerHeaderView(
                banners: banners,
                message: message,
                mailbox: mailboxManager.mailbox
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

    private func spamTypeFor(message: Message) -> SpamHeaderType? {
        if message.folder?.role != .spam,
           message.isSpam && !isSenderApproved(sender: message.from.first?.email) {
            if mailboxManager.mailbox.isSpamFilter {
                return .moveInSpam
            } else {
                return .enableSpamFilter
            }
        }

        if message.folder?.role == .spam,
           let sender = message.from.first, !message.isSpam && isSenderBlocked(sender: sender.email) {
            return .unblockRecipient(sender.email)
        }

        return nil
    }

    private func isSenderApproved(sender: String?) -> Bool {
        guard let sender,
              let sendersRestrictions = mailboxManager.mailbox.sendersRestrictions else {
            return false
        }
        return sendersRestrictions.authorizedSenders.contains { $0.email == sender }
    }

    private func isSenderBlocked(sender: String?) -> Bool {
        guard let sender,
              let sendersRestrictions = mailboxManager.mailbox.sendersRestrictions else {
            return false
        }
        return sendersRestrictions.blockedSenders.contains { $0.email == sender }
    }
}

#Preview {
    MessageSubHeaderView(message: PreviewHelper.sampleMessage, displayContentBlockedActionView: .constant(false))
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
