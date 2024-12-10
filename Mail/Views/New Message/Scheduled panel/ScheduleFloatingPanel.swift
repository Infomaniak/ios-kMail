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
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI

extension View {
    func scheduleFloatingPanel(
        isPresented: Binding<Bool>,
        draftSaveOption: Binding<SaveDraftOption?>,
        draftDate: Binding<Date?>,
        mailboxManager: MailboxManager,
        completionHandler: @escaping () -> Void
    ) -> some View {
        modifier(ScheduleFloatingPanel(
            isPresented: isPresented,
            draftSaveOption: draftSaveOption,
            draftDate: draftDate,
            mailBoxManager: mailboxManager,
            completionHandler: completionHandler
        ))
    }
}

struct ScheduleFloatingPanel: ViewModifier {
    @AppStorage(UserDefaults.shared.key(.lastScheduleInterval)) private var lastScheduleInterval: Double = 0

    @State private var isShowingDiscovery = false
    @State private var panelShouldBeShown = false
    @ModalState(wrappedValue: false, context: ContextKeys.schedule) private var customSchedule: Bool

    @Binding var isPresented: Bool
    @Binding var draftSaveOption: SaveDraftOption?
    @Binding var draftDate: Date?

    let mailBoxManager: MailboxManager
    let completionHandler: () -> Void

    func body(content: Content) -> some View {
        content
            .floatingPanel(isPresented: $isPresented, title: MailResourcesStrings.Localizable.scheduleSendingTitle) {
                ScheduleFloatingPanelView(
                    customSchedule: $customSchedule,
                    isShowingDiscovery: $isShowingDiscovery,
                    isFree: mailBoxManager.mailbox.isFree,
                    lastScheduleInterval: lastScheduleInterval,
                    setScheduleAction: setSchedule
                )
            }
            .customAlert(isPresented: $customSchedule) {
                CustomScheduleAlertView(
                    startingDate: draftDate ?? Date.minimumScheduleDelay,
                    confirmAction: setSchedule
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
            .discoveryPresenter(isPresented: $isShowingDiscovery) {
                DiscoveryView(item: .scheduleDiscovery, isShowingLaterButton: false) { _ in
                    isPresented = true
                }
            }
    }

    private func setSchedule(_ scheduleDate: Date) {
        lastScheduleInterval = scheduleDate.timeIntervalSince1970
        draftSaveOption = .schedule
        draftDate = scheduleDate
        completionHandler()
    }
}
