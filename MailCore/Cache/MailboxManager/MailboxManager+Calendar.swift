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

import Foundation

public extension MailboxManager {
    func attachmentCalendar(from messageUid: String) async throws {
        guard let liveMessage = getRealm().object(ofType: Message.self, forPrimaryKey: messageUid),
              let attachment = getCalendarAttachment(of: liveMessage) else {
            return
        }

        let calendarEvent = try await apiFetcher.calendarAttachment(attachment: attachment)

        await backgroundRealm.execute { realm in
            if let message = attachment.parent,
               let liveMessage = realm.object(ofType: Message.self, forPrimaryKey: message.uid) {
                try? realm.safeWrite {
                    liveMessage.calendarEvent = calendarEvent
                }
            }
        }
    }

    func calendarReply(to messageUid: String, reply: AttendeeState) async throws {
        guard let liveMessage = getRealm().object(ofType: Message.self, forPrimaryKey: messageUid),
              let attachment = getCalendarAttachment(of: liveMessage) else {
            return
        }

        let frozenMessage = liveMessage.freezeIfNeeded()
        if let eventAttachment = frozenMessage.calendarEvent, let event = eventAttachment.userStoredEvent {
            try await apiFetcher.calendarReplyAndUpdateRemoteCalendar(to: event, reply: reply)
        } else {
            try await apiFetcher.calendarReply(to: attachment, reply: reply)
        }

        try await attachmentCalendar(from: messageUid)
    }

    private func getCalendarAttachment(of message: Message) -> Attachment? {
        return message.attachments.first { $0.uti?.conforms(to: .calendarEvent) == true }?.freezeIfNeeded()
    }
}
