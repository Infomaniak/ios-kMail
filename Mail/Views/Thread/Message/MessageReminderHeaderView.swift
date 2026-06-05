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

import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct MessageReminderHeaderView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var mainViewState: MainViewState

    @State private var isShowingReschedulePanel = false

    let reminderDate: Date
    let senderNames: [String]
    let showBottomSeparator: Bool

    private var message: String {
        if reminderDate < .now && senderNames.count > 1 {
            return MailResourcesStrings.Localizable.reminderBeforeHeaderTitlePlural(
                formatNames(senderNames),
                DateFormatter.localizedString(from: reminderDate, dateStyle: .full, timeStyle: .short)
            )
        } else if reminderDate < .now {
            return MailResourcesStrings.Localizable.reminderBeforeHeaderTitle(
                formatNames(senderNames),
                DateFormatter.localizedString(from: reminderDate, dateStyle: .full, timeStyle: .short)
            )
        } else if reminderDate >= .now && senderNames.count > 1 {
            return MailResourcesStrings.Localizable.reminderAfterHeaderTitlePlural(
                formatNames(senderNames),
                DateFormatter.localizedString(from: reminderDate, dateStyle: .full, timeStyle: .short)
            )
        } else {
            return MailResourcesStrings.Localizable.reminderBeforeHeaderTitle(
                formatNames(senderNames),
                DateFormatter.localizedString(from: reminderDate, dateStyle: .full, timeStyle: .short)
            )
        }
    }

    var body: some View {
        MessageHeaderActionView(
            icon: MailResourcesAsset.alarmClock.swiftUIImage,
            message: message,
            showBottomSeparator: showBottomSeparator
        ) {}
    }

    private func formatNames(_ names: [String]) -> String {
        switch names.count {
        case 1:
            return "\(names[0])"
        case 2:
            return "\(names[0]) \(MailResourcesStrings.Localizable.linkingWord) \(names[1])"
        default:
            let allButLast = names.dropLast()
            return "\(allButLast.joined(separator: ", ")) \(MailResourcesStrings.Localizable.linkingWord) \(names.last!)"
        }
    }
}

#Preview {
    MessageReminderHeaderView(reminderDate: .now, senderNames: [""], showBottomSeparator: true)
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .environmentObject(MainViewState(
            mailboxManager: PreviewHelper.sampleMailboxManager,
            selectedFolder: PreviewHelper.sampleFolder
        ))
}
