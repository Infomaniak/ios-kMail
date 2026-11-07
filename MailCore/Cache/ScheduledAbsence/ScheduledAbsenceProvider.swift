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

import Algorithms
import Foundation
import InfomaniakCore

/// In-memory provider of the scheduled absences of other users (never persisted).
///
/// Mirrors the web cache: entries are kept per lowercased email for `cacheTTL` and reused only if they cover the
/// requested window (now → end of day of now + `lookAheadDays`). Concurrent lookups of the same email share one request.
/// Errors are treated as "no absence" and retried after `failureRetryDelay`.
public actor ScheduledAbsenceProvider {
    public static let maxEmails = 20
    static let cacheTTL: TimeInterval = 15 * 60
    static let failureRetryDelay: TimeInterval = 60
    static let lookAheadDays = 3

    private struct CacheEntry: Sendable {
        let absences: [ScheduledAbsenceEntry]
        let from: Date
        let to: Date
        let expiresAt: Date
    }

    private let apiFetcher: MailApiScheduledAbsenceFetchable
    private let featureFlagsManager: FeatureFlagsManageable
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private var cache = [String: CacheEntry]()
    private var inFlightRequests = [String: Task<Void, Never>]()

    public init(
        apiFetcher: MailApiScheduledAbsenceFetchable,
        featureFlagsManager: FeatureFlagsManageable,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.apiFetcher = apiFetcher
        self.featureFlagsManager = featureFlagsManager
        self.calendar = calendar
        self.now = now
    }

    /// Cached absences of the given recipients for the default window, keyed by lowercased email.
    /// Only recipients with at least one absence are returned.
    public func absences(for emails: [String]) async -> [String: [ScheduledAbsenceEntry]] {
        guard isFeatureEnabled else { return [:] }

        let normalizedEmails = Self.normalize(emails)
        guard !normalizedEmails.isEmpty else { return [:] }

        let currentDate = now()
        let window = Self.defaultWindow(now: currentDate, calendar: calendar)
        let emailsToFetch = normalizedEmails.filter { email in
            inFlightRequests[email] == nil && !isValid(cache[email], from: window.from, to: window.to, now: currentDate)
        }

        if !emailsToFetch.isEmpty {
            let request = Task {
                await self.fetchAndCache(emails: emailsToFetch, from: window.from, to: window.to, fetchedAt: currentDate)
            }
            for email in emailsToFetch {
                inFlightRequests[email] = request
            }
        }

        let pendingRequests = Set(normalizedEmails.compactMap { inFlightRequests[$0] })
        for request in pendingRequests {
            await request.value
        }

        return normalizedEmails.reduce(into: [String: [ScheduledAbsenceEntry]]()) { result, email in
            guard let absences = cache[email]?.absences, !absences.isEmpty else { return }
            result[email] = absences
        }
    }

    /// Absences of the given recipients for the default window starting at `date` (e.g. a scheduled draft),
    /// bypassing the cache.
    public func absences(for emails: [String], at date: Date) async -> [String: [ScheduledAbsenceEntry]] {
        guard isFeatureEnabled else { return [:] }

        let normalizedEmails = Self.normalize(emails)
        let window = Self.defaultWindow(now: date, calendar: calendar)
        guard !normalizedEmails.isEmpty,
              let fetchedAbsences = try? await apiFetcher.activeScheduledAbsences(
                  emails: normalizedEmails,
                  from: window.from,
                  to: window.to
              )
        else { return [:] }

        return fetchedAbsences.filter { !$0.value.isEmpty }
    }

    private var isFeatureEnabled: Bool {
        return featureFlagsManager.isEnabled(.scheduledAbsence)
    }

    private func fetchAndCache(emails: [String], from: Date, to: Date, fetchedAt: Date) async {
        let fetchedAbsences = try? await apiFetcher.activeScheduledAbsences(emails: emails, from: from, to: to)

        removeExpiredEntries(now: fetchedAt)
        let expiresAt = fetchedAt.addingTimeInterval(fetchedAbsences == nil ? Self.failureRetryDelay : Self.cacheTTL)
        for email in emails {
            cache[email] = CacheEntry(absences: fetchedAbsences?[email] ?? [], from: from, to: to, expiresAt: expiresAt)
            inFlightRequests[email] = nil
        }
    }

    private func isValid(_ entry: CacheEntry?, from: Date, to: Date, now: Date) -> Bool {
        guard let entry else { return false }
        return now < entry.expiresAt && entry.from <= from && entry.to >= to
    }

    private func removeExpiredEntries(now: Date) {
        cache = cache.filter { now < $0.value.expiresAt }
    }

    private static func normalize(_ emails: [String]) -> [String] {
        return Array(emails.map { $0.lowercased() }.filter { !$0.isEmpty }.uniqued().prefix(maxEmails))
    }

    /// now → end of day of (now + `lookAheadDays`)
    static func defaultWindow(now: Date, calendar: Calendar = .current) -> (from: Date, to: Date) {
        let lookAheadDate = calendar.date(byAdding: .day, value: lookAheadDays, to: now) ?? now
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lookAheadDate)) ?? lookAheadDate
        return (now, startOfNextDay.addingTimeInterval(-1))
    }
}
