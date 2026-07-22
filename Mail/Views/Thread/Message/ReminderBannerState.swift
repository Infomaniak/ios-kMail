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

public enum ReminderBannerState: Equatable {
    case pastEditable(date: Date, recipients: [String])

    case futureEditable(date: Date)

    case scheduled(deltaMinutes: Int)

    case displayOnly(date: Date, senders: [String])

    var title: String {
        switch self {
        case .pastEditable(let date, let recipients):
            return MailResourcesStrings.Localizable.reminderNoResponseHeaderTitle(
                formatNames(recipients),
                DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .short)
            )
        case .futureEditable(let date):
            return MailResourcesStrings.Localizable
                .callIfNoResponseHeaderTitleWithDate(DateFormatter.localizedString(
                    from: date,
                    dateStyle: .full,
                    timeStyle: .short
                ))
        case .scheduled(let deltaMinutes):
            return MailResourcesStrings.Localizable.callIfNoResponseHeaderTitle(headerMessageForDelta(deltaMinutes))
        case .displayOnly(let date, let senders):
            return headerMessageForRecipient(senders, reminderDate: date)
        }
    }

    private func formatNames(_ names: [String]) -> String {
        switch names.count {
        case 0:
            return ""
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) \(MailResourcesStrings.Localizable.linkingWord) \(names[1])"
        default:
            let allButLast = names.dropLast()
            return "\(allButLast.joined(separator: ", ")) \(MailResourcesStrings.Localizable.linkingWord) \(names.last ?? "")"
        }
    }

    private func headerMessageForDelta(_ reminderDelta: Int) -> String {
        if reminderDelta % 24 == 0 {
            let days = reminderDelta / (24 * 60)
            if days == 1 {
                return MailResourcesStrings.Localizable.daysBeforeSendingReminder(days)
            }
            return MailResourcesStrings.Localizable.daysBeforeSendingReminderPlural(days)
        } else {
            let hours = reminderDelta / 60
            if hours == 1 {
                return MailResourcesStrings.Localizable.hoursBeforeSendingReminderPlural(hours)
            }
            return MailResourcesStrings.Localizable.hoursBeforeSendingReminder(hours)
        }
    }

    private func headerMessageForRecipient(_ recipients: [String], reminderDate: Date) -> String {
        let formattedDate = DateFormatter.localizedString(from: reminderDate, dateStyle: .full, timeStyle: .short)
        let formattedNames = formatNames(recipients)

        if reminderDate < .now {
            if formattedNames.count > 1 {
                return MailResourcesStrings.Localizable.reminderAfterHeaderTitlePlural(formattedNames, formattedDate)
            } else {
                return MailResourcesStrings.Localizable.reminderAfterHeaderTitle(formattedNames, formattedDate)
            }
        } else {
            if formattedNames.count > 1 {
                return MailResourcesStrings.Localizable.reminderBeforeHeaderTitlePlural(formattedNames, formattedDate)
            } else {
                return MailResourcesStrings.Localizable.reminderBeforeHeaderTitle(formattedNames, formattedDate)
            }
        }
    }
}
