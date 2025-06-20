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

import DesignSystem
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct LockedMailboxView: View {
    @Environment(\.dismiss) private var dismiss

    let email: String

    var body: some View {
        VStack(spacing: IKPadding.medium) {
            MailResourcesAsset.mailboxError.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(height: 64)
            Text(MailResourcesStrings.Localizable.lockedMailboxBottomSheetTitle(email))
                .textStyle(.header2)
                .multilineTextAlignment(.center)
            Text(MailResourcesStrings.Localizable.lockedMailboxBottomSheetDescription)
                .textStyle(.bodySecondary)
                .multilineTextAlignment(.center)
                .padding(.vertical, value: .large)

            Button(MailResourcesStrings.Localizable.externalDialogConfirmButton) {
                dismiss()
            }
            .buttonStyle(.ikBorderedProminent)
            .controlSize(.large)
            .ikButtonFullWidth(true)
        }
        .padding(.horizontal, value: .large)
        .padding(.top, value: .medium)
        .matomoView(view: ["LockedMailboxView"])
    }
}

#Preview {
    Text("Preview")
        .mailFloatingPanel(isPresented: .constant(true)) {
            LockedMailboxView(email: PreviewHelper.sampleMailbox.email)
        }
}
