/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import DesignSystem
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct CalendarChoiceButton: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @Binding var selectedChoice: AttendeeState?

    let choice: AttendeeState
    let isSelected: Bool
    let messageUid: String?

    var body: some View {
        Button(action: sendReply) {
            HStack(spacing: IKPadding.mini) {
                choice.icon
                    .iconSize(.medium)
                    .foregroundStyle(choice.color)
                Text(choice.label)
                    .textStyle(.bodyMediumSecondary)
            }
            .padding(.horizontal, value: .small)
            .padding(.vertical, value: .mini)
            .overlay {
                RoundedRectangle(cornerRadius: UIConstants.buttonsRadius)
                    .stroke(isSelected ? choice.color : MailResourcesAsset.textFieldBorder.swiftUIColor)
            }
        }
        .allowsHitTesting(!isSelected)
    }

    @MainActor
    private func sendReply() {
        guard let messageUid else { return }

        @InjectService var matomoUtils: MatomoUtils
        matomoUtils.track(eventWithCategory: .calendarEvent, name: "reply\(choice.matomoName.capitalized)")

        let oldChoice = selectedChoice
        selectedChoice = choice
        Task {
            @InjectService var snackbarPresenter: IKSnackBarPresentable
            do {
                try await mailboxManager.replyToCalendarEvent(messageUid: messageUid, reply: choice)
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarCalendarChoiceSent)
            } catch {
                selectedChoice = oldChoice
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorCalendarChoiceCouldNotBeSent)
            }
        }
    }
}

#Preview {
    VStack {
        HStack {
            CalendarChoiceButton(selectedChoice: .constant(nil), choice: .yes, isSelected: false, messageUid: "")
            CalendarChoiceButton(selectedChoice: .constant(nil), choice: .maybe, isSelected: false, messageUid: "")
            CalendarChoiceButton(selectedChoice: .constant(nil), choice: .no, isSelected: false, messageUid: "")
        }

        HStack {
            CalendarChoiceButton(selectedChoice: .constant(nil), choice: .yes, isSelected: true, messageUid: "")
            CalendarChoiceButton(selectedChoice: .constant(nil), choice: .maybe, isSelected: true, messageUid: "")
            CalendarChoiceButton(selectedChoice: .constant(nil), choice: .no, isSelected: true, messageUid: "")
        }
    }
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
