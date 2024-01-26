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

public extension MailApiFetcher {
    func calendarAttachment(attachment: Attachment) async throws -> CalendarEventResponse {
        guard let resource = attachment.resource else {
            throw MailError.resourceError
        }
        return try await perform(request: authenticatedRequest(.resource(
            resource,
            queryItems: [URLQueryItem(name: "format", value: "render")]
        ))).data
    }

    @discardableResult
    func calendarReply(to attachment: Attachment, reply: AttendeeState) async throws -> CalendarNotStoredEventReplyResponse {
        guard let resource = attachment.resource else {
            throw MailError.resourceError
        }

        let replyRequest = CalendarReplyRequest(reply: reply)
        return try await perform(request: authenticatedRequest(
            .calendarReply(resource: resource),
            method: .post,
            parameters: replyRequest
        )).data
    }

    @discardableResult
    func calendarReplyAndUpdateRemoteCalendar(to event: CalendarEvent, reply: AttendeeState) async throws -> Bool {
        let replyRequest = CalendarReplyRequest(reply: reply)
        return try await perform(request: authenticatedRequest(
            .calendarReplyAndUpdateEvent(id: event.id),
            method: .post,
            parameters: replyRequest
        )).data
    }
}
