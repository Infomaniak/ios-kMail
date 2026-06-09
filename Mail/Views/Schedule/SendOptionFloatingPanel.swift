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
import InfomaniakCoreSwiftUI
import InfomaniakDI
import KSuite
import MailCore
import MailCoreUI
import MailResources
import MyKSuite
import RealmSwift
import SwiftModalPresentation
import SwiftUI

extension View {
    func sendOptionFloatingPanel(
        isPresented: Binding<Bool>,
        isUpdating: Bool,
        initialDate: Date? = nil,
        dismissView: (() -> Void)? = nil,
        completionHandler: @escaping (Date) -> Void
    ) -> some View {
        modifier(
            SendOptionFloatingPanel(
                isShowingFloatingPanel: isPresented,
                isUpdating: isUpdating,
                initialDate: initialDate,
                dismissView: dismissView,
                completionHandler: completionHandler
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
    @State private var isScheduleEnabled = false
    @State private var selectedReminderOption: ReminderOption?
    @State private var contentHeight: CGFloat = 0
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var isShowingCustomScheduleAlert = false

    @Binding var isShowingFloatingPanel: Bool

    let isUpdating: Bool
    let initialDate: Date?
    let dismissView: (() -> Void)?
    let completionHandler: (Date) -> Void

    private let type: ScheduleType = .scheduledDraft

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
                        isScheduleEnabled: $isScheduleEnabled,
                        selectedReminderOption: $selectedReminderOption,
                        contentHeight: $contentHeight,
                        type: type,
                        initialDate: initialDate,
                        completionHandler: completionHandler
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
                    CustomScheduleAlertView(type: type, date: initialDate, isUpdating: isUpdating, confirmAction: { date in
                        selectedReminderOption = .custom(date: date)
                    }) {
                        panelShouldBeShown = true
                    }
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
}
