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

import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI

extension View {
    func scheduleFloatingPanel(
        draft: Draft,
        mailboxManager: MailboxManager,
        isPresented: Binding<Bool>,
        dismissMessageView: @escaping () -> Void
    ) -> some View {
        modifier(ScheduleFloatingPanel(
            draft: draft,
            mailBoxManager: mailboxManager,
            isPresented: isPresented,
            dismissMessageView: dismissMessageView
        ))
    }
}

struct ScheduleFloatingPanel: ViewModifier {
    @AppStorage(UserDefaults.shared.key(.lastScheduleInterval)) private var lastScheduleInterval: Double = 0

    @ObservedRealmObject var draft: Draft

    @State private var selectedDate = Date.now

    let mailBoxManager: MailboxManager

    @Binding var isPresented: Bool

    @ModalState(wrappedValue: false, context: ContextKeys.schedule) private var customSchedule: Bool

    let dismissMessageView: () -> Void

    func body(content: Content) -> some View {
        content
            .floatingPanel(isPresented: $isPresented, title: MailResourcesStrings.Localizable.scheduleSendingTitle) {
                ScheduleFloatingPanelView(
                    draft: draft,
                    isPresented: $isPresented,
                    customSchedule: $customSchedule,
                    lastScheduleInterval: lastScheduleInterval,
                    dismissMessageView: dismissMessageView,
                    setScheduleAction: setSchedule
                )
            }
            .customAlert(isPresented: $customSchedule) {
                CustomScheduleModalView(
                    isFloatingPanelPresented: $isPresented,
                    selectedDate: $selectedDate,
                    confirmAction: setSchedule
                )
            }
    }

    private func setSchedule(_ scheduleDate: Date) {
        lastScheduleInterval = scheduleDate.timeIntervalSince1970
        $draft.action.wrappedValue = .schedule
        $draft.scheduleDate.wrappedValue = scheduleDate.ISO8601WithTimeZone
        $draft.delay.wrappedValue = nil
        dismissMessageView()
    }
}
