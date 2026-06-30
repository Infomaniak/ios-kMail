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
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

extension View {
    func sendOptionFloatingPanel(
        isPresented: Binding<Bool>,
        isUpdating: Bool,
        initialDate: Date? = nil,
        dismissView: (() -> Void)? = nil,
        selectedScheduleOption: Binding<ScheduleOption?>,
        selectedReminderOption: Binding<ReminderOption?>,
        selectedReminderVisibility: Binding<ReminderVisibility?>
    ) -> some View {
        modifier(
            SendOptionFloatingPanel(
                isShowingFloatingPanel: isPresented,
                selectedScheduleOption: selectedScheduleOption,
                selectedReminderOption: selectedReminderOption,
                selectedReminderVisibility: selectedReminderVisibility,
                isUpdating: isUpdating,
                initialDate: initialDate,
                dismissView: dismissView
            )
        )
    }
}

struct SendOptionFloatingPanel: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingMyKSuiteUpgrade = false
    @State private var isShowingKSuiteProUpgrade = false
    @State private var isShowingMailPremiumUpgrade = false
    @State private var panelShouldBeShown = false
    @State private var isReminderEnabled = false
    @State private var isScheduleEnabled = false
    @State private var contentHeight: CGFloat = 0
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var isShowingCustomScheduleAlert = false
    @State private var customAlertType: ScheduleType = .scheduledDraft

    @Binding var isShowingFloatingPanel: Bool
    @Binding var selectedScheduleOption: ScheduleOption?
    @Binding var selectedReminderOption: ReminderOption?
    @Binding var selectedReminderVisibility: ReminderVisibility?

    let isUpdating: Bool
    let initialDate: Date?
    let dismissView: (() -> Void)?

    private var isShowingAnyPanel: Bool {
        return isShowingFloatingPanel || isShowingCustomScheduleAlert
    }

    private var detents: Set<PresentationDetent> {
        contentHeight > 0 ? [.height(contentHeight)] : [.medium]
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isShowingFloatingPanel) {
                ScrollView {
                    SendOptionFloatingPanelView(
                        isShowingCustomScheduleAlert: $isShowingCustomScheduleAlert,
                        isShowingMyKSuiteUpgrade: $isShowingMyKSuiteUpgrade,
                        isShowingKSuiteProUpgrade: $isShowingKSuiteProUpgrade,
                        isShowingMailPremiumUpgrade: $isShowingMailPremiumUpgrade,
                        isReminderEnabled: $isReminderEnabled,
                        isScheduleEnabled: $isScheduleEnabled,
                        selectedReminderOption: $selectedReminderOption,
                        selectedScheduleOption: $selectedScheduleOption,
                        selectedReminderVisibility: $selectedReminderVisibility,
                        customAlertType: $customAlertType,
                        contentHeight: $contentHeight,
                        initialDate: initialDate
                    )
                }
                .scrollBounceBehavior(.basedOnSize)
                .environmentObject(mailboxManager)
                .presentationDetents(detents, selection: $selectedDetent)
                .presentationDragIndicator(.visible)
                .presentationBackground(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)
                .animation(.default, value: contentHeight)
                .onChange(of: contentHeight) { newHeight in
                    guard newHeight > 0 else { return }
                    selectedDetent = .height(newHeight)
                }
                .onDisappear {
                    if !isShowingAnyPanel {
                        dismissView?()
                    }
                }
                .mailCustomAlert(isPresented: $isShowingCustomScheduleAlert) {
                    if customAlertType == .reminder(type: .option) {
                        CustomReminderAlertView(
                            confirmAction: { option in
                                selectedReminderOption = option
                            },
                            cancelAction: {
                                panelShouldBeShown = true
                            }
                        )
                    } else if customAlertType == .reminder(type: .visibility) {
                        CustomReminderVisibilityAlertView(currentVisibility: selectedReminderVisibility) { visibility in
                            selectedReminderVisibility = visibility
                        } cancelAction: {
                            panelShouldBeShown = true
                        }

                    } else {
                        CustomScheduleAlertView(
                            type: customAlertType,
                            date: initialDate,
                            isUpdating: isUpdating,
                            confirmAction: { date in
                                if customAlertType == .scheduledDraft {
                                    selectedScheduleOption = .custom(date: date)
                                }
                            },
                            cancelAction: {
                                panelShouldBeShown = true
                            }
                        )
                    }
                }
            }
    }
}
