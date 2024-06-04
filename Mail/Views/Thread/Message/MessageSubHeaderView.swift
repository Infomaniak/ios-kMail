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

import InfomaniakCore
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct MessageSubHeaderView: View {
    @ObservedRealmObject var message: Message

    @Binding var displayContentBlockedActionView: Bool

    private var isRemoteContentBlocked: Bool {
        return (UserDefaults.shared.displayExternalContent == .askMe || message.folder?.role == .spam)
            && !message.localSafeDisplay
    }

    var body: some View {
        if isRemoteContentBlocked && displayContentBlockedActionView {
            MessageHeaderActionView(
                icon: MailResourcesAsset.emailActionWarning.swiftUIImage,
                message: MailResourcesStrings.Localizable.alertBlockedImagesDescription
            ) {
                Button(MailResourcesStrings.Localizable.alertBlockedImagesDisplayContent) {
                    withAnimation {
                        $message.localSafeDisplay.wrappedValue = true
                    }
                }
                .buttonStyle(.ikLink(isInlined: true))
                .controlSize(.small)
            }
        }

        if let event = message.calendarEventResponse?.frozenEvent, event.type == .event {
            CalendarView(event: event)
                .padding(.horizontal, value: .regular)
        }

        if !message.attachments.filter({ $0.disposition == .attachment || $0.contentId == nil }).isEmpty || message.swissTransferUuid != nil {
            AttachmentsView(message: message)
        }
    }
}

#Preview {
    MessageSubHeaderView(message: PreviewHelper.sampleMessage, displayContentBlockedActionView: .constant(false))
}
