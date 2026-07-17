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
import MailCore
import MailResources
import RealmSwift

extension Draft {
    var scheduleOption: ScheduleOption? {
        guard let scheduleDate else { return nil }
        for option in ScheduleOption.allPresetOptions {
            if let optionDate = option.date, optionDate == scheduleDate {
                return option
            }
        }
        if let keyPath = ScheduleType.scheduledDraft.lastCustomScheduleDateKeyPath {
            let lastScheduledDate = UserDefaults.shared[keyPath: keyPath]
            if lastScheduledDate == scheduleDate {
                return .lastSchedule(value: scheduleDate)
            }
        }
        return .custom(date: scheduleDate)
    }

    func setScheduleOption(_ option: ScheduleOption?, mailboxManager: MailboxManager) {
        try? mailboxManager.writeTransaction { realm in
            guard let liveDraft = realm.object(ofType: Draft.self, forPrimaryKey: localUUID) else { return }
            liveDraft.scheduleDate = option?.date
        }
    }
}
