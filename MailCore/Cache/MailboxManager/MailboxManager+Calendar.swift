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
        let (_, frozenAttachment) = try getFrozenMessageAndCalendarAttachment(messageUid: messageUid)

        let calendarEventResponse = try await apiFetcher.calendarEvent(from: frozenAttachment)
        await saveCalendarEventResponse(to: messageUid, eventResponse: calendarEventResponse)
    }

    func replyToCalendarEvent(messageUid: String, reply: AttendeeState) async throws {
        let (frozenMessage, frozenAttachment) = try getFrozenMessageAndCalendarAttachment(messageUid: messageUid)

        // Currently, when a user reply, we need to check whether its event is stored
        // in Infomaniak Calendar or not.
        // If the event is stored in Calendar, we call a route that notifies guests and
        // updates the event. Otherwise we call a route that only notifies guests.
        if let eventAttachment = frozenMessage.calendarEventResponse, let event = eventAttachment.userStoredEvent {
            try await apiFetcher.replyToCalendarEventAndUpdateCalendar(event: event, reply: reply)
        } else {
            try await apiFetcher.replyToCalendarEvent(attachment: frozenAttachment, reply: reply)
        }

        try await calendarEvent(from: messageUid)
    }

    func importICSEventToCalendar(messageUid: String) async throws -> CalendarEvent {
        let (_, frozenAttachment) = try getFrozenMessageAndCalendarAttachment(messageUid: messageUid)

        let storedEvent = try await apiFetcher.importICSEventToCalendar(attachment: frozenAttachment).event
        try await calendarEvent(from: messageUid)

        return storedEvent
    }
}

extension MailboxManager {
    private func getFrozenMessageAndCalendarAttachment(messageUid: String) throws -> (Message, Attachment) {
        guard let frozenMessage = getRealm().object(ofType: Message.self, forPrimaryKey: messageUid)?.freezeIfNeeded(),
              let frozenAttachment = getFrozenCalendarAttachment(from: frozenMessage) else {
            throw MailError.noCalendarAttachmentFound
        }

        return (frozenMessage, frozenAttachment)
    }

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
