/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import MailCoreUI
import MailResources
import SwiftUI

enum ComposeMessageDateHeaderBinding {
    case reminder(Binding<ReminderOption?>)
    case schedule(Binding<ScheduleOption?>)

    var message: String {
        switch self {
        case .reminder(let reminderOption):
            switch reminderOption.wrappedValue {
            case .customDays, .customHours:
                return MailResourcesStrings.Localizable.callIfNoResponseHeaderTitle(reminderOption.wrappedValue?.subtitle ?? "")
            default:
                return MailResourcesStrings.Localizable.callIfNoResponseHeaderTitle(reminderOption.wrappedValue?.title ?? "")
            }
        case .schedule(let scheduleOption):
            return MailResourcesStrings.Localizable
                .scheduleSendingHeaderTitle(scheduleOption.wrappedValue?.date?.formatted(.messageHeader) ?? "")
        }
    }

    var icon: Image {
        switch self {
        case .reminder:
            return MailResourcesAsset.alarmClock.swiftUIImage
        case .schedule:
            return MailResourcesAsset.clockPaperplane.swiftUIImage
        }
    }
}

struct ComposeMessageDateHeaderView: View {
    @Binding var isShowingSendOptionsPanel: Bool
    let option: ComposeMessageDateHeaderBinding

    var body: some View {
        MessageHeaderActionView(
            icon: option.icon,
            message: option.message,
            showTopSeparator: false,
            showBottomSeparator: true,
            shouldDisplayActions: true
        ) {
            HStack {
                Button(MailResourcesStrings.Localizable.buttonReschedule) {
                    isShowingSendOptionsPanel = true
                }
                MessageHeaderDivider()
                Button(MailResourcesStrings.Localizable.buttonCancel) {
                    switch option {
                    case .reminder(let binding):
                        binding.wrappedValue = nil
                    case .schedule(let binding):
                        binding.wrappedValue = nil
                    }
                }
            }
        }
    }
}

#Preview {
    ComposeMessageDateHeaderView(
        isShowingSendOptionsPanel: .constant(false),
        option: .schedule(.constant(nil))
    )
}
