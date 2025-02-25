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

enum ScheduleFloatingPanelOrigin {
    case snooze
    case schedule

    var matomoName: String {
        switch self {
        case .snooze:
            "snoozeCustomDate"
        case .schedule:
            "scheduledCustomDate"
        }
    }
}

extension View {
    func scheduleFloatingPanel(
        isPresented: Binding<Bool>,
        draftSaveOption: Binding<SaveDraftOption?>,
        draftDate: Binding<Date?>,
        mailboxManager: MailboxManager,
        origin: ScheduleFloatingPanelOrigin,
        completionHandler: @escaping () -> Void
    ) -> some View {
        modifier(ScheduleFloatingPanel(
            isPresented: isPresented,
            draftSaveOption: draftSaveOption,
            draftDate: draftDate,
            mailBoxManager: mailboxManager,
            origin: origin,
            completionHandler: completionHandler
        ))
    }
}

struct ScheduleFloatingPanel: ViewModifier {
    @AppStorage(UserDefaults.shared.key(.lastScheduleInterval)) private var lastScheduleInterval: Double = 0
    @LazyInjectService private var matomo: MatomoUtils

    @State private var isShowingMyKSuiteUpgrade = false
    @State private var panelShouldBeShown = false
    @ModalState(wrappedValue: false, context: ContextKeys.schedule) private var customSchedule: Bool

    @Binding var isPresented: Bool
    @Binding var draftSaveOption: SaveDraftOption?
    @Binding var draftDate: Date?

    let mailBoxManager: MailboxManager
    let origin: ScheduleFloatingPanelOrigin
    let completionHandler: () -> Void

    func body(content: Content) -> some View {
        content
            .floatingPanel(isPresented: $isPresented, title: MailResourcesStrings.Localizable.scheduleSendingTitle) {
                ScheduleFloatingPanelView(
                    customSchedule: $customSchedule,
                    isShowingMyKSuiteUpgrade: $isShowingMyKSuiteUpgrade,
                    isMyKSuiteStandard: mailBoxManager.mailbox.isFree && mailBoxManager.mailbox.isLimited,
                    lastScheduleInterval: lastScheduleInterval,
                    setScheduleAction: setSchedule
                )
            }
            .customAlert(isPresented: $customSchedule) {
                CustomScheduleAlertView(
                    startingDate: draftDate ?? Date.minimumScheduleDelay,
                    confirmAction: setCustomSchedule
                ) {
                    panelShouldBeShown = true
                }
                .onDisappear {
                    if panelShouldBeShown {
                        isPresented = true
                        panelShouldBeShown = false
                    }
                }
            }
            .myKSuitePanel(isPresented: $isShowingMyKSuiteUpgrade, configuration: .mail)
            .onChange(of: isShowingMyKSuiteUpgrade) { value in
                guard value else { return }
                matomo.track(eventWithCategory: .myKSuiteUpgrade, name: origin.matomoName)
            }
    }

    private func setSchedule(_ scheduleDate: Date) {
        draftSaveOption = .schedule
        draftDate = scheduleDate
        completionHandler()
    }

    private func setCustomSchedule(_ scheduleDate: Date) {
        lastScheduleInterval = scheduleDate.timeIntervalSince1970
        setSchedule(scheduleDate)
    }
}
