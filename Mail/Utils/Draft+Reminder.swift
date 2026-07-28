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

import MailCore
import MailResources
import RealmSwift

extension Draft {
    private static let hoursInMinutes = 60
    private static let daysInMinutes = 24 * hoursInMinutes

    var reminderOption: ReminderOption? {
        guard let reminder else { return nil }
        switch reminder.delta {
        case ReminderOption.oneDay.inMinutes:
            return .oneDay
        case ReminderOption.threeDays.inMinutes:
            return .threeDays
        case ReminderOption.sevenDays.inMinutes:
            return .sevenDays
        default:
            if let hours = getValue(for: reminder.delta, divisor: Self.hoursInMinutes, range: 1 ... 23) {
                return .customHours(hours)
            }
            if let days = getValue(for: reminder.delta, divisor: Self.daysInMinutes, range: 1 ... 30) {
                return .customDays(days)
            }
            return nil
        }
    }

    func setReminderOption(_ option: ReminderOption?, mailboxManager: MailboxManager) {
        try? mailboxManager.writeTransaction { realm in
            guard let liveDraft = realm.object(ofType: Draft.self, forPrimaryKey: localUUID) else { return }

            guard let minutes = option?.inMinutes else {
                liveDraft.reminder = nil
                return
            }

            liveDraft.reminder = DraftReminder(delta: minutes, display: liveDraft.reminder?.display ?? true)
        }
    }

    var reminderVisibility: ReminderVisibility? {
        guard let reminder else { return nil }
        return reminder.display ? .recipientsAndMe : .onlyMe
    }

    func setReminderVisibility(_ visibility: ReminderVisibility?, mailboxManager: MailboxManager) {
        try? mailboxManager.writeTransaction { realm in
            guard let liveDraft = realm.object(ofType: Draft.self, forPrimaryKey: localUUID) else { return }

            liveDraft.reminder = DraftReminder(
                delta: liveDraft.reminder?.delta ?? 1440,
                display: visibility.map { $0 == .recipientsAndMe } == true
            )
        }
    }

    private func getValue(for reminderDelta: Int, divisor: Int, range: ClosedRange<Int>) -> Int? {
        guard reminderDelta % divisor == 0 else { return nil }
        let value = reminderDelta / divisor
        guard range.contains(value) else { return nil }
        return value
    }
}
