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

extension ScheduleType {
    var floatingPanelTitle: String {
        switch self {
        case .scheduledDraft:
            return MailResourcesStrings.Localizable.scheduleSendingTitle
        case .snooze:
            return MailResourcesStrings.Localizable.actionSnooze
        }
    }
}

extension View {
    func scheduleFloatingPanel(
        isPresented: Binding<Bool>,
        type: ScheduleType,
        isUpdating: Bool,
        initialDate: Date? = nil,
        dismissView: (() -> Void)? = nil,
        completionHandler: @escaping (Date) -> Void
    ) -> some View {
        modifier(
            ScheduleFloatingPanel(
                isShowingFloatingPanel: isPresented,
                type: type,
                isUpdating: isUpdating,
                initialDate: initialDate,
                dismissView: dismissView,
                completionHandler: completionHandler
            )
        )
    }
}

struct ScheduleFloatingPanel: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingMyKSuiteUpgrade = false
    @State private var isShowingKSuiteProUpgrade = false
    @State private var isShowingMailPremiumUpgrade = false
    @State private var panelShouldBeShown = false
    @ModalState(wrappedValue: false, context: ContextKeys.schedule) private var isShowingCustomScheduleAlert: Bool

    @Binding var isShowingFloatingPanel: Bool

    let type: ScheduleType
    let isUpdating: Bool
    let initialDate: Date?
    let dismissView: (() -> Void)?
    let completionHandler: (Date) -> Void

    private var isShowingAnyPanel: Bool {
        return isShowingFloatingPanel || isShowingCustomScheduleAlert
    }

    func body(content: Content) -> some View {
        content
            .mailFloatingPanel(isPresented: $isShowingFloatingPanel, title: type.floatingPanelTitle) {
                ScheduleFloatingPanelView(
                    isShowingCustomScheduleAlert: $isShowingCustomScheduleAlert,
                    isShowingMyKSuiteUpgrade: $isShowingMyKSuiteUpgrade,
                    isShowingKSuiteProUpgrade: $isShowingKSuiteProUpgrade,
                    isShowingMailPremiumUpgrade: $isShowingMailPremiumUpgrade,
                    type: type,
                    initialDate: initialDate,
                    completionHandler: completionHandler
                )
                .environmentObject(mailboxManager)
                .onDisappear {
                    if !isShowingAnyPanel {
                        dismissView?()
                    }
                }
            }
            .mailCustomAlert(isPresented: $isShowingCustomScheduleAlert) {
                CustomScheduleAlertView(type: type, date: initialDate, isUpdating: isUpdating, confirmAction: completionHandler) {
                    panelShouldBeShown = true
                }
                .onDisappear {
                    if panelShouldBeShown {
                        isShowingFloatingPanel = true
                        panelShouldBeShown = false
                    } else if !isShowingAnyPanel {
                        dismissView?()
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
