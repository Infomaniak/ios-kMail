//
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
import SwiftModalPresentation
import SwiftUI

struct MessageScheduleHeaderView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let scheduleDate: Date
    let draftResource: String

    @ModalState(wrappedValue: false, context: ContextKeys.schedule) private var customSchedule: Bool
    @ModalState(wrappedValue: false, context: ContextKeys.schedule) private var modifyMessage: Bool

    var body: some View {
        MessageHeaderActionView(
            icon: MailResourcesAsset.scheduleSend.swiftUIImage,
            message: "Cet e-mail sera envoyé à cette date : \(DateFormatter.localizedString(from: scheduleDate, dateStyle: .full, timeStyle: .short))"
        ) {
            Button("Reprogrammer") {
                customSchedule = true
            }
            .buttonStyle(.ikBorderless(isInlined: true))
            .controlSize(.small)

            Divider()
                .frame(height: 20)

            Button("Modifier") {
                modifyMessage = true
            }
            .buttonStyle(.ikBorderless(isInlined: true))
            .controlSize(.small)
        }
        .customAlert(isPresented: $customSchedule) {
            CustomScheduleModalView(isFloatingPanelPresented: .constant(false), confirmAction: changeScheduleDate)
        }
        .customAlert(isPresented: $modifyMessage) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Modifier l'envoie")
                Text(
                    "Programmation annulée. Ce message sera déplacé dans vos brouillons pour être envoyé quand vous le souhaitez."
                )
                .font(.subheadline)
                ModalButtonsView(primaryButtonTitle: "Modifier",
                                 secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel,
                                 primaryButtonAction: modifySchedule)
            }
        }
    }

    private func changeScheduleDate(_ selectedDate: Date) {
        Task {
            try await mailboxManager.apiFetcher.changeDraftSchedule(draftResource: draftResource, scheduleDateIso8601: selectedDate.ISO8601WithTimeZone)
        }
    }

    private func modifySchedule() {
        Task {
            
            try await mailboxManager.apiFetcher.deleteSchedule(draftResource: draftResource)
        }
    }
}

#Preview {
    VStack(spacing: IKPadding.medium) {
        IKDivider()
        MessageScheduleHeaderView(scheduleDate: .now, draftResource: "")
        IKDivider()
    }
    .ignoresSafeArea()
}
