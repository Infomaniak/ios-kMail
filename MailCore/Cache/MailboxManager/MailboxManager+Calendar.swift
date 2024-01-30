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
    func calendarEvent(from messageUid: String) async throws {
        guard let liveMessage = getRealm().object(ofType: Message.self, forPrimaryKey: messageUid),
              let attachment = getFrozenCalendarAttachment(from: liveMessage) else {
            return
        }

        let calendarEventResponse = try await apiFetcher.calendarEvent(from: attachment)
        await saveCalendarEventResponse(to: messageUid, eventResponse: calendarEventResponse)
    }

    func replyToCalendarEvent(messageUid: String, reply: AttendeeState) async throws {
        guard let liveMessage = getRealm().object(ofType: Message.self, forPrimaryKey: messageUid),
              let attachment = getFrozenCalendarAttachment(from: liveMessage) else {
            return
        }

        // Currently, when a user reply, we need to check whether its event is stored
        // in Infomaniak Calendar or not.
        // If the event is stored in Calendar, we call a route that notifies guests and
        // updates the event. Otherwise we call a route that only notifies guests.
        let frozenMessage = liveMessage.freezeIfNeeded()
        if let eventAttachment = frozenMessage.calendarEventResponse, let event = eventAttachment.userStoredEvent {
            try await apiFetcher.replyToCalendarEventAndUpdateCalendar(event: event, reply: reply)
        } else {
            try await apiFetcher.replyToCalendarEvent(attachment: attachment, reply: reply)
        }

        try await calendarEvent(from: messageUid)
    }

    func importICSEventToCalendar() async throws {}
}

extension MailboxManager {
    private func getFrozenCalendarAttachment(from message: Message) -> Attachment? {
        return message.attachments.first { $0.uti?.conforms(to: .calendarEvent) == true }?.freezeIfNeeded()
    }

    private func saveCalendarEventResponse(to messageUid: String, eventResponse: CalendarEventResponse) async {
        await backgroundRealm.execute { realm in
            if let liveMessage = realm.object(ofType: Message.self, forPrimaryKey: messageUid) {
                try? realm.safeWrite {
                    liveMessage.calendarEventResponse = eventResponse
                }
            }
        }
    }
}
