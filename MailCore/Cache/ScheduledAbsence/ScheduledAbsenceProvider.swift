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
import InfomaniakCore

/// In-memory provider of the scheduled absences of other users (never persisted).
///
/// Mirrors the web cache: entries are kept per lowercased email for `cacheTTL` and reused only if they cover the
/// requested window (now → end of day of now + `lookAheadDays`). Errors are swallowed and treated as "no absence".
public actor ScheduledAbsenceProvider {
    public static let cacheTTL: TimeInterval = 15 * 60
    public static let maxEmails = 20
    public static let lookAheadDays = 3

    struct CacheEntry: Sendable {
        let absences: [ScheduledAbsenceEntry]
        let from: Date
        let to: Date
        let fetchedAt: Date
    }

    private let apiFetcher: MailApiScheduledAbsenceFetchable
    private let featureFlagsManager: FeatureFlagsManageable
    private let now: @Sendable () -> Date
    private let cache = SendableDictionary<String, CacheEntry>()

    public init(
        apiFetcher: MailApiScheduledAbsenceFetchable,
        featureFlagsManager: FeatureFlagsManageable,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.apiFetcher = apiFetcher
        self.featureFlagsManager = featureFlagsManager
        self.now = now
    }

    /// Cached absences of the given recipients for the default window, keyed by lowercased email.
    /// Only recipients with at least one absence are returned.
    public func absences(for emails: [String], forceRefresh: Bool = false) async -> [String: [ScheduledAbsenceEntry]] {
        guard isFeatureEnabled else { return [:] }

        let normalizedEmails = Self.normalize(emails)
        guard !normalizedEmails.isEmpty else { return [:] }

        let currentDate = now()
        let window = Self.defaultWindow(now: currentDate)
        let emailsToFetch = normalizedEmails.filter { email in
            forceRefresh || !isValid(cache[email], from: window.from, to: window.to, now: currentDate)
        }

        if !emailsToFetch.isEmpty,
           let fetchedAbsences = try? await apiFetcher.activeScheduledAbsences(
               emails: emailsToFetch,
               from: window.from,
               to: window.to
           ) {
            for email in emailsToFetch {
                cache[email] = CacheEntry(
                    absences: fetchedAbsences[email] ?? [],
                    from: window.from,
                    to: window.to,
                    fetchedAt: currentDate
                )
            }
        }

        return normalizedEmails.reduce(into: [String: [ScheduledAbsenceEntry]]()) { result, email in
            guard let absences = cache[email]?.absences, !absences.isEmpty else { return }
            result[email] = absences
        }
    }

    /// Absences of the given recipients for a custom window (e.g. a scheduled draft), bypassing the cache.
    public func absences(for emails: [String], from: Date, to: Date) async -> [String: [ScheduledAbsenceEntry]] {
        guard isFeatureEnabled, to > from else { return [:] }

        let normalizedEmails = Self.normalize(emails)
        guard !normalizedEmails.isEmpty,
              let fetchedAbsences = try? await apiFetcher.activeScheduledAbsences(emails: normalizedEmails, from: from, to: to)
        else { return [:] }

        return fetchedAbsences.filter { !$0.value.isEmpty }
    }

    /// Last absences fetched by `absences(for:forceRefresh:)` for a recipient, without any network call.
    public nonisolated func cachedAbsences(for email: String) -> [ScheduledAbsenceEntry] {
        let key = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return cache[key]?.absences ?? []
    }

    private var isFeatureEnabled: Bool {
        return featureFlagsManager.isEnabled(.scheduledAbsence)
    }

    private func isValid(_ entry: CacheEntry?, from: Date, to: Date, now: Date) -> Bool {
        guard let entry else { return false }
        return now.timeIntervalSince(entry.fetchedAt) < Self.cacheTTL && entry.from <= from && entry.to >= to
    }

    static func normalize(_ emails: [String]) -> [String] {
        var seenEmails = Set<String>()
        var result = [String]()
        for email in emails {
            let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !normalizedEmail.isEmpty, seenEmails.insert(normalizedEmail).inserted else { continue }
            result.append(normalizedEmail)
            if result.count == maxEmails {
                break
            }
        }
        return result
    }

    /// now → end of day of (now + `lookAheadDays`)
    static func defaultWindow(now: Date, calendar: Calendar = .current) -> (from: Date, to: Date) {
        let lookAheadDate = calendar.date(byAdding: .day, value: lookAheadDays, to: now) ?? now
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lookAheadDate)) ?? lookAheadDate
        return (now, startOfNextDay.addingTimeInterval(-1))
    }
}
