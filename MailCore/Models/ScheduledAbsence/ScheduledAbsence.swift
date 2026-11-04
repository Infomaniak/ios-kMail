/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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

import Foundation

/// A planned absence of another user, as returned by `/pim/scheduled-absence/active`.
///
/// `statusText` and `autoReplyContent` are authored by another user: only render them as plain text.
public struct ScheduledAbsence: Codable, Sendable, Hashable {
    public let uuid: String
    /// Emoji name, e.g. `palm_tree`
    public let statusEmoji: String?
    public let statusText: String?
    public let autoReplyContent: String?
    public let disableKchatNotification: Bool
    public let autoDeclineInvitation: Bool
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case uuid
        case statusEmoji
        case statusText
        case autoReplyContent
        case disableKchatNotification
        case autoDeclineInvitation
        case createdAt
        case updatedAt
    }

    public init(
        uuid: String,
        statusEmoji: String? = nil,
        statusText: String? = nil,
        autoReplyContent: String? = nil,
        disableKchatNotification: Bool = false,
        autoDeclineInvitation: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.uuid = uuid
        self.statusEmoji = statusEmoji
        self.statusText = statusText
        self.autoReplyContent = autoReplyContent
        self.disableKchatNotification = disableKchatNotification
        self.autoDeclineInvitation = autoDeclineInvitation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
        statusEmoji = try? container.decodeIfPresent(String.self, forKey: .statusEmoji)
        statusText = try? container.decodeIfPresent(String.self, forKey: .statusText)
        autoReplyContent = try? container.decodeIfPresent(String.self, forKey: .autoReplyContent)
        disableKchatNotification = (try? container.decodeIfPresent(Bool.self, forKey: .disableKchatNotification)) ?? false
        autoDeclineInvitation = (try? container.decodeIfPresent(Bool.self, forKey: .autoDeclineInvitation)) ?? false
        createdAt = try? container.decodeFlexibleDateIfPresent(forKey: .createdAt)
        updatedAt = try? container.decodeFlexibleDateIfPresent(forKey: .updatedAt)
    }

    /// The auto-reply content trimmed, or `nil` when empty.
    public var displayableAutoReplyContent: String? {
        guard let content = autoReplyContent?.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty else {
            return nil
        }
        return content
    }
}

public struct ScheduledAbsenceOccurrence: Codable, Sendable, Hashable {
    public let start: Date
    /// Exclusive end. For full-day occurrences, it is the first day back (UTC calendar date).
    public let end: Date
    public let fullday: Bool

    enum CodingKeys: String, CodingKey {
        case start
        case end
        case fullday
    }

    public init(start: Date, end: Date, fullday: Bool) {
        self.start = start
        self.end = end
        self.fullday = fullday
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = try container.decodeFlexibleDate(forKey: .start)
        end = try container.decodeFlexibleDate(forKey: .end)
        fullday = (try? container.decodeIfPresent(Bool.self, forKey: .fullday)) ?? false
    }

    public func isOngoing(at now: Date, timeZone: TimeZone = .current) -> Bool {
        let referenceDate = referenceDate(for: now, timeZone: timeZone)
        return start <= referenceDate && referenceDate < end
    }

    public func isUpcoming(at now: Date, timeZone: TimeZone = .current) -> Bool {
        return start > referenceDate(for: now, timeZone: timeZone)
    }

    /// Full-day occurrences are UTC calendar dates compared by day: map `now` to its local calendar date anchored in UTC.
    private func referenceDate(for now: Date, timeZone: TimeZone) -> Date {
        guard fullday, let utcTimeZone = TimeZone(identifier: "UTC") else { return now }

        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = timeZone
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = utcTimeZone

        let components = localCalendar.dateComponents([.year, .month, .day], from: now)
        return utcCalendar.date(from: components) ?? now
    }
}

public struct ScheduledAbsenceEntry: Codable, Sendable, Hashable, Identifiable {
    public let absence: ScheduledAbsence
    public let occurrence: ScheduledAbsenceOccurrence

    public var id: String {
        return "\(absence.uuid)-\(occurrence.start.timeIntervalSince1970)"
    }

    public init(absence: ScheduledAbsence, occurrence: ScheduledAbsenceOccurrence) {
        self.absence = absence
        self.occurrence = occurrence
    }
}

/// `data` payload of `/pim/scheduled-absence/active`: `{ "<email>": [Entry] | null }`.
/// Malformed entries are dropped instead of failing the whole response.
struct ScheduledAbsencesResponse: Decodable {
    let absencesByEmail: [String: [ScheduledAbsenceEntry]]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawData = try container.decode([String: [LossyDecodable<ScheduledAbsenceEntry>]?].self)

        var absencesByEmail = [String: [ScheduledAbsenceEntry]]()
        for (email, entries) in rawData {
            let key = email.lowercased()
            absencesByEmail[key, default: []].append(contentsOf: entries?.compactMap(\.value) ?? [])
        }
        self.absencesByEmail = absencesByEmail
    }
}

private struct LossyDecodable<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDate(forKey key: Key) throws -> Date {
        if let date = try? decode(Date.self, forKey: key) {
            return date
        }

        let rawDate = try decode(String.self, forKey: key)
        guard let date = ScheduledAbsenceDateParser.date(from: rawDate) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Invalid ISO 8601 date")
        }
        return date
    }

    func decodeFlexibleDateIfPresent(forKey key: Key) throws -> Date? {
        guard contains(key), try !decodeNil(forKey: key) else {
            return nil
        }
        return try decodeFlexibleDate(forKey: key)
    }
}

enum ScheduledAbsenceDateParser {
    static func date(from string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }
}
