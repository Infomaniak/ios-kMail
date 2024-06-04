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

import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct LockedMailboxView: View {
    @LazyInjectService private var accountManager: AccountManager

    @Environment(\.dismiss) private var dismiss

    let mailbox: Mailbox

    var body: some View {
        VStack(spacing: UIPadding.regular) {
            MailResourcesAsset.mailboxError.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(height: 64)
            Text(attributedString())
                .textStyle(.header2)
                .multilineTextAlignment(.center)
            Text(MailResourcesStrings.Localizable.lockedMailboxDescription)
                .textStyle(.bodySecondary)
                .multilineTextAlignment(.center)
                .padding(.vertical, value: .medium)

            Button(MailResourcesStrings.Localizable.externalDialogConfirmButton) {
                dismiss()
            }
            .buttonStyle(.ikPlain)
            .controlSize(.large)
            .ikButtonFullWidth(true)
        }
        .padding(.horizontal, value: .medium)
        .padding(.top, value: .regular)
        .matomoView(view: ["LockedMailboxView"])
    }

    func attributedString() -> AttributedString {
        do {
            var text = try AttributedString(markdown: MailResourcesStrings.Localizable
                .blockedMailboxTitle("**\(mailbox.email)**"))

            if let range = text.range(of: mailbox.email) {
                text[range].foregroundColor = MailResourcesAsset.textPrimaryColor.swiftUIColor
            }

            return text
        } catch {
            return ""
        }
    }
}

#Preview {
    Text("Preview")
        .floatingPanel(isPresented: .constant(true)) {
            LockedMailboxView(mailbox: PreviewHelper.sampleMailbox)
        }
}
