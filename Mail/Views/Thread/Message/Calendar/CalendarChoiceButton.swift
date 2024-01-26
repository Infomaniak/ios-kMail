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

import MailCore
import MailResources
import SwiftUI

struct CalendarChoiceButton: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let choice: AttendeeState
    let isSelected: Bool
    let messageUid: String?

    var body: some View {
        Button(action: sendReply) {
            HStack(spacing: UIPadding.small) {
                IKIcon(choice.icon)
                    .foregroundStyle(choice.color)
                Text(choice.label)
                    .textStyle(.bodyMediumSecondary)
            }
            .padding(.horizontal, value: .intermediate)
            .padding(.vertical, value: .small)
            .overlay {
                RoundedRectangle(cornerRadius: UIConstants.buttonsRadius)
                    .stroke(isSelected ? choice.color : MailResourcesAsset.textFieldBorder.swiftUIColor)
            }
        }
        .allowsHitTesting(!isSelected)
    }

    private func sendReply() {
        Task {
            guard let messageUid else { return }
            try await mailboxManager.calendarReply(to: messageUid, reply: choice)
        }
    }
}

#Preview {
    VStack {
        HStack {
            CalendarChoiceButton(choice: .yes, isSelected: false, messageUid: "")
            CalendarChoiceButton(choice: .maybe, isSelected: false, messageUid: "")
            CalendarChoiceButton(choice: .no, isSelected: false, messageUid: "")
        }

        HStack {
            CalendarChoiceButton(choice: .yes, isSelected: true, messageUid: "")
            CalendarChoiceButton(choice: .maybe, isSelected: true, messageUid: "")
            CalendarChoiceButton(choice: .no, isSelected: true, messageUid: "")
        }
    }
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
