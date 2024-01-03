//
/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import MailCore
import MailResources
import SwiftUI

struct CalendarAttendeeAvatarView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let recipient: Recipient
    var choice: CalendarChoice?

    var body: some View {
        AvatarView(
            mailboxManager: mailboxManager,
            contactConfiguration: .recipient(recipient: recipient, contextMailboxManager: mailboxManager),
            size: 33
        )
        .overlay {
            Circle()
                .stroke(MailResourcesAsset.backgroundColor.swiftUIColor)
        }
        .padding(.trailing, 2)
        .padding(.bottom, 4)
        .overlay(alignment: .bottomTrailing) {
            if let choice {
                Circle()
                    .fill(MailResourcesAsset.backgroundColor.swiftUIColor)
                    .frame(width: 17, height: 17)
                    .overlay {
                        choice.icon.swiftUIImage
                            .resizable()
                            .foregroundStyle(choice.color)
                            .padding(1)
                    }
            }
        }
    }
}

#Preview {
    VStack {
        CalendarAttendeeAvatarView(recipient: PreviewHelper.sampleRecipient1, choice: .yes)
        CalendarAttendeeAvatarView(recipient: PreviewHelper.sampleRecipient1, choice: .maybe)
        CalendarAttendeeAvatarView(recipient: PreviewHelper.sampleRecipient1, choice: .no)
        CalendarAttendeeAvatarView(recipient: PreviewHelper.sampleRecipient1, choice: nil)
    }
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(MailResourcesAsset.textFieldColor.swiftUIColor)
}
