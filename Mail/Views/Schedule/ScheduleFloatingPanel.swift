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
        initialDate: Date? = nil,
        completionHandler: @escaping (Date) -> Void
    ) -> some View {
        modifier(
            ScheduleFloatingPanel(
                isShowingFloatingPanel: isPresented,
                type: type,
                initialDate: initialDate,
                completionHandler: completionHandler
            )
        )
    }
}

struct ScheduleFloatingPanel: ViewModifier {
    @State private var isShowingMyKSuiteUpgrade = false
    @State private var panelShouldBeShown = false
    @ModalState(wrappedValue: false, context: ContextKeys.schedule) private var isShowingCustomScheduleAlert: Bool

    @Binding var isShowingFloatingPanel: Bool

    let type: ScheduleType
    let initialDate: Date?
    let completionHandler: (Date) -> Void

    func body(content: Content) -> some View {
        content
            .floatingPanel(isPresented: $isShowingFloatingPanel, title: type.floatingPanelTitle) {
                ScheduleFloatingPanelView(
                    isShowingCustomScheduleAlert: $isShowingCustomScheduleAlert,
                    isShowingMyKSuiteUpgrade: $isShowingMyKSuiteUpgrade,
                    type: type,
                    setScheduleAction: completionHandler
                )
            }
            .customAlert(isPresented: $isShowingCustomScheduleAlert) {
                CustomScheduleAlertView(type: type, date: initialDate, confirmAction: completionHandler) {
                    panelShouldBeShown = true
                }
                .onDisappear {
                    if panelShouldBeShown {
                        isShowingFloatingPanel = true
                        panelShouldBeShown = false
                    }
                }
            }
            .myKSuitePanel(isPresented: $isShowingMyKSuiteUpgrade, configuration: .mail)
    }

    private func setSchedule(_ scheduleDate: Date) {
//        draftSaveOption = .schedule
//        draftDate = scheduleDate
    }
}
