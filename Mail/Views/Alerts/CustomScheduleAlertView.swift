/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct CustomScheduleAlertView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @State private var isShowingError = false
    @State private var selectedDate: Date

    let confirmAction: (Date) -> Void
    let cancelAction: (() -> Void)?

    private let maximumDelay = Date.now.addingTimeInterval(60 * 60 * 24 * 365 * 10) // 10 years

    private var isDelayTooShort: Bool {
        selectedDate < Date.minimumScheduleDelay
    }

    init(startingDate: Date, confirmAction: @escaping (Date) -> Void, cancelAction: (() -> Void)? = nil) {
        _selectedDate = .init(initialValue: startingDate)
        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.datePickerTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)

            DatePicker(
                MailResourcesStrings.Localizable.datePickerTitle,
                selection: $selectedDate,
                in: Date.minimumScheduleDelay.addingTimeInterval(60) ... maximumDelay
            )
            .labelsHidden()
            .onChange(of: selectedDate) { newDate in
                isShowingError = newDate < Date.minimumScheduleDelay || newDate > maximumDelay
            }

            Text(MailResourcesStrings.Localizable.errorScheduleDelayTooShortPlural(5))
                .textStyle(.labelError)
                .padding(.top, value: .micro)
                .opacity(isShowingError ? 1 : 0)
                .padding(.bottom, value: .mini)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonScheduleTitle,
                             secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel,
                             primaryButtonEnabled: !isShowingError,
                             primaryButtonAction: executeActionIfPossible,
                             secondaryButtonAction: cancelAction)
        }
    }

    private func executeActionIfPossible() throws {
        guard !isDelayTooShort else {
            isShowingError = true
            throw MailError.tooShortScheduleDelay
        }
        confirmAction(selectedDate)
        matomo.track(eventWithCategory: .scheduleSend, name: "customSchedule")
    }
}
