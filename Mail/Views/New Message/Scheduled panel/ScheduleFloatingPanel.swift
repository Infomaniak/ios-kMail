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
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

extension View {
    func scheduleFloatingPanel(isPresented: Binding<Bool>) -> some View {
        modifier(ScheduleFloatingPanel(isPresented: isPresented, lastSchedule: .distantFuture))
    }
}

struct ScheduleFloatingPanel: ViewModifier {
    @Binding var isPresented: Bool

    @ModalState(wrappedValue: false, context: ContextKeys.schedule) private var customSchedule: Bool

    let lastSchedule: Date?

    func body(content: Content) -> some View {
        content
            .floatingPanel(isPresented: $isPresented) {
                ScheduleFloatingPanelView(isPresented: $isPresented, customSchedule: $customSchedule, lastSchedule: lastSchedule)
            }
            .customAlert(isPresented: $customSchedule) {
                ScheduleModalView(isFloatingPanelPresented: $isPresented)
            }
    }
}

#Preview {
    Text("Oui c'est moi")
        .scheduleFloatingPanel(isPresented: .constant(true))
}
