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

public extension PreviewHelper {
    static let sampleScheduledAbsenceEntry1 = ScheduledAbsenceEntry(
        absence: ScheduledAbsence(
            uuid: "preview-absence-1",
            statusEmoji: "palm_tree",
            statusText: "On holiday",
            autoReplyContent: "Hello, I am on holiday and will be back soon.\nBest regards,\nFrom Example"
        ),
        occurrence: ScheduledAbsenceOccurrence(
            start: Date().addingTimeInterval(-86400),
            end: Date().addingTimeInterval(3 * 86400),
            fullday: true
        )
    )

    static let sampleScheduledAbsenceEntry2 = ScheduledAbsenceEntry(
        absence: ScheduledAbsence(uuid: "preview-absence-2"),
        occurrence: ScheduledAbsenceOccurrence(
            start: Date().addingTimeInterval(-3600),
            end: Date().addingTimeInterval(5 * 86400),
            fullday: false
        )
    )

    static let sampleScheduledAbsencesByEmail = [
        sampleRecipient1.email: [sampleScheduledAbsenceEntry1],
        sampleRecipient2.email: [sampleScheduledAbsenceEntry2]
    ]

    static let sampleScheduledAbsenceSingleSummary = ScheduledAbsenceSummary(
        absencesByEmail: [sampleRecipient1.email: [sampleScheduledAbsenceEntry1]],
        orderedEmails: [sampleRecipient1.email],
        now: Date()
    )

    static let sampleScheduledAbsenceMultipleSummary = ScheduledAbsenceSummary(
        absencesByEmail: sampleScheduledAbsencesByEmail,
        orderedEmails: [sampleRecipient1.email, sampleRecipient2.email],
        now: Date()
    )
}
