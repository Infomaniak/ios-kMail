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
import InfomaniakCoreCommonUI
import InfomaniakDI
import KSuite
import MailCore
import MailCoreUI
import MailResources
import MyKSuite
import RealmSwift
import SwiftUI

struct SendOptionFloatingPanelView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @Binding var isShowingCustomScheduleAlert: Bool
    @Binding var isShowingMyKSuiteUpgrade: Bool
    @Binding var isShowingKSuiteProUpgrade: Bool
    @Binding var isShowingMailPremiumUpgrade: Bool
    @Binding var isReminderEnabled: Bool
    @Binding var isScheduleEnabled: Bool
    @Binding var customAlertType: ScheduleType
    @Binding var contentHeight: CGFloat

    @ObservedRealmObject var draft: Draft

    private var isCustomOptionLimited: Bool {
        let pack = mailboxManager.mailbox.pack
        return pack == .myKSuiteFree || pack == .kSuiteFree || pack == .starterPack
    }

    private var displayedReminderOption: ReminderOption {
        if let option = draft.reminderOption, option.isCustom {
            return option
        }
        return .custom
    }

    private var displayedScheduleOption: ScheduleOption {
        if let option = draft.scheduleOption, option.isCustom {
            return option
        }
        return .custom(date: .now)
    }

    private var scheduleOptions: [ScheduleOption] {
        var seenDateOptions = Set<Date>()

        var filteredOptions = ScheduleOption.allPresetOptions.filter { option in
            guard option.canBeDisplayed, let date = option.date else { return false }
            if seenDateOptions.contains(date) {
                return false
            } else {
                seenDateOptions.insert(date)
                return true
            }
        }

        if let keyPath = ScheduleType.scheduledDraft.lastCustomScheduleDateKeyPath {
            let lastScheduledDate = UserDefaults.shared[keyPath: keyPath]
            let lastScheduledOption = ScheduleOption.lastSchedule(value: lastScheduledDate)
            if lastScheduledOption.canBeDisplayed, !seenDateOptions.contains(lastScheduledDate) {
                filteredOptions.insert(.lastSchedule(value: lastScheduledDate), at: 0)
            }
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

            if mailboxManager.featureAvailableProvider.isAvailable(.reminder) {
                Toggle(isOn: $isReminderEnabled) {
                    Label {
                        Text(ScheduleType.reminder(type: .option).floatingPanelTitle)
                    } icon: {
                        MailResourcesAsset.alarmClock.iconSize(.large)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .tint(.accentColor)
                .padding(value: .medium)

                if isReminderEnabled {
                    ReminderVisibilityCell(
                        visibility: draft.reminderVisibility ?? .recipientsAndMe,
                        isSelected: false,
                        isInModal: false
                    ) {
                        if isCustomOptionLimited {
                            showUpgradeBottomSheet()
                        } else {
                            customAlertType = .reminder(type: .visibility)
                            isShowingCustomScheduleAlert = true
                        }
                    }

                    IKDivider(type: .item)
                    VStack(spacing: 0) {
                        ForEach(ReminderOption.presetCases, id: \.self) { option in
                            ReminderCell(
                                option: option,
                                isSelected: draft.reminderOption == option
                            ) {
                                draft.setReminderOption(option, mailboxManager: mailboxManager)
                            }
                        }

                        ReminderCell(
                            option: displayedReminderOption,
                            isSelected: draft.reminderOption?.isCustom == true,
                            showUpgradeChip: isCustomOptionLimited
                        ) {
                            if isCustomOptionLimited {
                                showUpgradeBottomSheet()
                            } else {
                                customAlertType = .reminder(type: .option)
                                isShowingCustomScheduleAlert = true
                            }
                        }
                    }
                }

                IKDivider(type: .item)
            }

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
                            isSelected: draft.scheduleOption == option
                        ) {
                            draft.setScheduleOption(option, mailboxManager: mailboxManager)
                        }
                    }

                    let isCustomSelected = draft.scheduleOption?.isCustom == true

                    ScheduleCell(
                        option: displayedScheduleOption,
                        isSelected: isCustomSelected,
                        showUpgradeChip: isCustomOptionLimited
                    ) {
                        if isCustomOptionLimited {
                            showUpgradeBottomSheet()
                        } else {
                            customAlertType = .scheduledDraft
                            isShowingCustomScheduleAlert = true
                        }
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
                draft.setReminderOption(draft.reminderOption ?? .oneDay, mailboxManager: mailboxManager)
                draft.setReminderVisibility(draft.reminderVisibility ?? .recipientsAndMe, mailboxManager: mailboxManager)
            } else {
                // Reset when toggled OFF
                draft.setReminderOption(nil, mailboxManager: mailboxManager)
                draft.setReminderVisibility(nil, mailboxManager: mailboxManager)
            }
        }
        .onChange(of: isScheduleEnabled) { newValue in
            if newValue {
                // Auto-select first available option when toggled ON
                draft.setScheduleOption(draft.scheduleOption ?? scheduleOptions.first, mailboxManager: mailboxManager)
            } else {
                // Reset when toggled OFF
                draft.setScheduleOption(nil, mailboxManager: mailboxManager)
            }
        }
        .mailMyKSuiteFloatingPanel(isPresented: $isShowingMyKSuiteUpgrade, configuration: .mail)
        .kSuitePanel(
            isPresented: $isShowingKSuiteProUpgrade,
            backgroundColor: MailResourcesAsset.backgroundSecondaryColor.swiftUIColor,
            configuration: .standard,
            isAdmin: mailboxManager.mailbox.ownerOrAdmin
        )
        .mailPremiumPanel(isPresented: $isShowingMailPremiumUpgrade)
    }

    private func showUpgradeBottomSheet() {
        @InjectService var matomo: MatomoUtils

        switch mailboxManager.mailbox.pack {
        case .myKSuiteFree:
            matomo.track(eventWithCategory: .myKSuiteUpgradeBottomSheet, name: "customOption")
            isShowingMyKSuiteUpgrade = true
        case .kSuiteFree:
            matomo.track(eventWithCategory: .kSuiteProUpgradeBottomSheet, name: "customOption")
            isShowingKSuiteProUpgrade = true
        case .starterPack:
            matomo.track(eventWithCategory: .mailPremiumUpgradeBottomSheet, name: "customOption")
            isShowingMailPremiumUpgrade = true
        default:
            break
        }
    }
}

#Preview {
    SendOptionFloatingPanelView(
        isShowingCustomScheduleAlert: .constant(false),
        isShowingMyKSuiteUpgrade: .constant(false),
        isShowingKSuiteProUpgrade: .constant(false),
        isShowingMailPremiumUpgrade: .constant(false),
        isReminderEnabled: .constant(true),
        isScheduleEnabled: .constant(true),
        customAlertType: .constant(.scheduledDraft),
        contentHeight: .constant(0),
        draft: Draft()
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
