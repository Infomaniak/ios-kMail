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

struct LockedMailboxView: View {
    @Environment(\.dismiss) private var dismiss

    let lockedMailbox: Mailbox
    var body: some View {
        VStack(spacing: 16) {
            MailResourcesAsset.mailboxError.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(height: 64)
            Text(MailResourcesStrings.Localizable.lockedMailboxTitle(lockedMailbox.email))
                .textStyle(.header2)
                .multilineTextAlignment(.center)
            Text(MailResourcesStrings.Localizable.lockedMailboxDescription)
                .textStyle(.bodySecondary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 24)

            MailButton(label: MailResourcesStrings.Localizable.buttonClose) {
                dismiss()
            }
            .mailButtonStyle(.link)
            .mailButtonFullWidth(true)
        }
        .padding(.horizontal, UIConstants.bottomSheetHorizontalPadding)
        .padding(.top, 16)
    }
}

struct LockedMailboxView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview")
            .floatingPanel(isPresented: .constant(true)) {
                LockedMailboxView(lockedMailbox: PreviewHelper.sampleMailbox)
            }
    }
}
