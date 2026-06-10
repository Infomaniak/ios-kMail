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
    @Binding var isShowingMyKSuiteUpgrade: Bool
    @Binding var isShowingKSuiteProUpgrade: Bool
    @Binding var isShowingMailPremiumUpgrade: Bool
    @Binding var isScheduleEnabled: Bool
    @Binding var selectedReminderOption: ReminderOption?
    @Binding var selectedScheduleOption: ScheduleOption?
    @Binding var customAlertType: ScheduleType
    @Binding var contentHeight: CGFloat

    @State private var isReminderEnabled = false

    let initialDate: Date?
    let completionHandler: (Date) -> Void

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
                HStack(spacing: IKPadding.mini) {
                    MailResourcesAsset.alarmClock.iconSize(.large)
                        .foregroundStyle(Color.accentColor)
                    Text(ScheduleType.reminder.floatingPanelTitle)
                        .textStyle(.body)
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
                    ForEach(ReminderOption.allCases) { option in
                        let displayOption = option.isCustom && selectedReminderOption?.isCustom == true
                            ? selectedReminderOption!
                            : option
                        let isSelected = option.isCustom
                            ? selectedReminderOption?.isCustom == true
                            : selectedReminderOption == option

                        ReminderCell(
                            option: displayOption,
                            isSelected: isSelected
                        ) {
                            if option.isCustom {
                                customAlertType = .reminder
                                isShowingCustomScheduleAlert = true
                            } else {
                                selectedReminderOption = option
                            }
                        }

                        if option != ReminderOption.allCases.last {
                            IKDivider(type: .item)
                        }
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
    }
}

#Preview {
    SendOptionFloatingPanelView(
        isShowingCustomScheduleAlert: .constant(false),
        isShowingMyKSuiteUpgrade: .constant(false),
        isShowingKSuiteProUpgrade: .constant(false),
        isShowingMailPremiumUpgrade: .constant(false),
        isScheduleEnabled: .constant(true),
        selectedReminderOption: .constant(.oneDay),
        selectedScheduleOption: .constant(nil),
        customAlertType: .constant(.scheduledDraft),
        contentHeight: .constant(0),
        initialDate: nil
    ) { _ in }
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
