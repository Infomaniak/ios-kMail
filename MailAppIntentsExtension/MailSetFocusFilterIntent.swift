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

import AppIntents
import Foundation
import MailCore

struct MailSetFocusFilterIntent: SetFocusFilterIntent {
    @Parameter(title: "filterFocusDarkModeTitle", default: false)
    var alwaysUseDarkMode: Bool

    @Parameter(title: "settingsAccentColor")
    var preferredAccent: AccentColorEntity?

    @Parameter(title: "settingsThreadListDensityTitle")
    var preferredDensity: ThreadDensityEntity?

    @Parameter(title: "filterFocusAllowedMailboxesTitle", optionsProvider: AccountOptionsProvider())
    var allowedMailboxes: [AccountEntity]?

    static var title: LocalizedStringResource = "filterFocusTitle"
    static var description: IntentDescription = "filterFocusDescription"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "activeFocusFilterTitle")
    }

    var appContext: FocusFilterAppContext {
        let predicate: NSPredicate
        if let allowedMailboxes, !allowedMailboxes.isEmpty {
            predicate = NSPredicate(format: "SELF IN %@", allowedMailboxes.map { $0.id })
        } else {
            predicate = NSPredicate(value: true)
        }
        return FocusFilterAppContext(notificationFilterPredicate: predicate)
    }

    static func suggestedFocusFilters(for context: FocusFilterSuggestionContext) async -> [MailSetFocusFilterIntent] {
        let exampleFilter = MailSetFocusFilterIntent()
        exampleFilter.alwaysUseDarkMode = true
        return [exampleFilter]
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.shared.theme = alwaysUseDarkMode ? .dark : DefaultPreferences.theme
        UserDefaults.shared.accentColor = preferredAccent?.accentColor ?? DefaultPreferences.accentColor
        UserDefaults.shared.threadDensity = preferredDensity?.threadDensity ?? DefaultPreferences.threadDensity

        return .result()
    }
}
