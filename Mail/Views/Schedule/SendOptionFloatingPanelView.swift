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

import DesignSystem
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct SendOptionFloatingPanelView: View {
    @Binding var isShowingCustomScheduleAlert: Bool
    @Binding var isReminderEnabled: Bool
    @Binding var isScheduleEnabled: Bool
    @Binding var selectedReminderOption: ReminderOption?
    @Binding var selectedScheduleOption: ScheduleOption?
    @Binding var customAlertType: ScheduleType
    @Binding var contentHeight: CGFloat

    let initialDate: Date?

    private var scheduleOptions: [ScheduleOption] {
        var seenDateOptions = Set<Date>()
        if let initialDate {
            seenDateOptions.insert(initialDate)
        }

        var filteredOptions = ScheduleOption.allPresetOptions.filter { option in
            guard option.canBeDisplayed, let date = option.date else { return false }
            if seenDateOptions.contains(date) {
                return false
            } else {
                seenDateOptions.insert(date)
                return true
            }
        }

        let lastScheduledDate = UserDefaults.shared[keyPath: ScheduleType.scheduledDraft.lastCustomScheduleDateKeyPath]
        let lastScheduledOption = ScheduleOption.lastSchedule(value: lastScheduledDate)
        if lastScheduledOption.canBeDisplayed, !seenDateOptions.contains(lastScheduledDate) {
            filteredOptions.insert(.lastSchedule(value: lastScheduledDate), at: 0)
        }

        return filteredOptions
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(MailResourcesStrings.Localizable.sendOptions)
                .font(Font(UIFont.preferredFont(forTextStyle: .headline)))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, value: .medium)
                .padding(.bottom, value: .small)

            IKDivider(type: .item)

            Toggle(isOn: $isReminderEnabled) {
                Label {
                    Text(ScheduleType.reminder.floatingPanelTitle)
                } icon: {
                    MailResourcesAsset.alarmClock.iconSize(.large)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .tint(.accentColor)
            .padding(value: .medium)

            if isReminderEnabled {
                Text(MailResourcesStrings.Localizable.explanationActionCallIfNoResponse)
                    .textStyle(.bodySmallSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, IKPadding.medium + IKIconSize.large.rawValue + IKPadding.mini)
                    .padding(.trailing, value: .medium)
                    .padding(.bottom, value: .small)

                IKDivider(type: .item)
                VStack(spacing: 0) {
                    ForEach(ReminderOption.presetCases) { option in
                        ReminderCell(
                            option: option,
                            isSelected: selectedReminderOption == option
                        ) {
                            selectedReminderOption = option
                        }

                        IKDivider(type: .item)
                    }

                    let customOption: ReminderOption = selectedReminderOption?.isCustom == true
                        ? selectedReminderOption!
                        : .custom(date: .now)
                    let isCustomSelected = selectedReminderOption?.isCustom == true

                    ReminderCell(
                        option: customOption,
                        isSelected: isCustomSelected
                    ) {
                        customAlertType = .reminder
                        isShowingCustomScheduleAlert = true
                    }
                }
            }

            IKDivider(type: .item)

            Toggle(isOn: $isScheduleEnabled) {
                Label {
                    Text(ScheduleType.scheduledDraft.floatingPanelTitle)
                } icon: {
                    MailResourcesAsset.clockPaperplane.iconSize(.large)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .tint(.accentColor)
            .padding(value: .medium)

            if isScheduleEnabled {
                IKDivider(type: .item)
                VStack(spacing: 0) {
                    ForEach(scheduleOptions) { option in
                        ScheduleCell(
                            option: option,
                            isSelected: selectedScheduleOption == option
                        ) {
                            selectedScheduleOption = option
                        }

                        IKDivider(type: .item)
                    }

                    let customOption: ScheduleOption = selectedScheduleOption?.isCustom == true
                        ? selectedScheduleOption!
                        : .custom(date: .now)
                    let isCustomSelected = selectedScheduleOption?.isCustom == true

                    ScheduleCell(
                        option: customOption,
                        isSelected: isCustomSelected
                    ) {
                        customAlertType = .scheduledDraft
                        isShowingCustomScheduleAlert = true
                    }
                }
            }
        }
        .background {
            GeometryReader { geometry in
                Color.clear
                    .onAppear { contentHeight = geometry.size.height }
                    .onChange(of: geometry.size.height) { contentHeight = $0 }
            }
        }
        .onChange(of: isReminderEnabled) { newValue in
            if newValue {
                // Auto-select first option when toggled ON
                selectedReminderOption = .oneDay
            } else {
                // Reset when toggled OFF
                selectedReminderOption = nil
            }
        }
        .onChange(of: isScheduleEnabled) { newValue in
            if newValue {
                // Auto-select first available option when toggled ON
                selectedScheduleOption = scheduleOptions.first
            } else {
                // Reset when toggled OFF
                selectedScheduleOption = nil
            }
        }
        .onChange(of: selectedScheduleOption) { newScheduleOption in
            // Only adjust custom reminder if it becomes invalid (before schedule date)
            guard isReminderEnabled,
                  let reminderOption = selectedReminderOption,
                  reminderOption.isCustom,
                  let reminderDate = reminderOption.date,
                  let scheduleDate = newScheduleOption?.date,
                  reminderDate <= scheduleDate else { return }
            selectedReminderOption = .oneDay
        }
    }
}

#Preview {
    SendOptionFloatingPanelView(
        isShowingCustomScheduleAlert: .constant(false),
        isReminderEnabled: .constant(true),
        isScheduleEnabled: .constant(true),
        selectedReminderOption: .constant(.oneDay),
        selectedScheduleOption: .constant(nil),
        customAlertType: .constant(.scheduledDraft),
        contentHeight: .constant(0),
        initialDate: nil
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
