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

import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct AttendeeAvatarView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let attendee: Attendee

    private var cachedContact: CommonContact {
        return CommonContactCache.getOrCreateContact(contactConfiguration: .correspondent(
            correspondent: attendee,
            contextMailboxManager: mailboxManager
        ))
    }

    var body: some View {
        AvatarView(
            mailboxManager: mailboxManager,
            contactConfiguration: .contact(contact: cachedContact),
            size: 32 + UIConstants.avatarBorderLineWidth
        )
        .overlay {
            Circle()
                .stroke(MailResourcesAsset.backgroundColor.swiftUIColor, lineWidth: UIConstants.avatarBorderLineWidth)
        }
        .padding([.bottom, .trailing], UIPadding.verySmall)
        .overlay(alignment: .bottomTrailing) {
            if let state = attendee.state {
                Circle()
                    .fill(MailResourcesAsset.backgroundColor.swiftUIColor)
                    .frame(width: 16 + UIConstants.avatarBorderLineWidth, height: 16 + UIConstants.avatarBorderLineWidth)
                    .overlay {
                        state.icon.swiftUIImage
                            .resizable()
                            .foregroundStyle(state.color)
                            .padding(UIConstants.avatarBorderLineWidth)
                    }
            }
        }
    }
}

#Preview {
    VStack {
        AttendeeAvatarView(attendee: PreviewHelper.sampleAttendee1)
        AttendeeAvatarView(attendee: PreviewHelper.sampleAttendee2)
        AttendeeAvatarView(attendee: PreviewHelper.sampleAttendee3)
        AttendeeAvatarView(attendee: PreviewHelper.sampleAttendee4)
    }
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(MailResourcesAsset.textFieldColor.swiftUIColor)
}
