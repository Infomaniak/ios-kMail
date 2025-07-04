/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import MailResources
import SwiftUI

struct EncryptionButton: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isLoadingRecipientsAutoEncrypt = false

    let draft: Draft
    let didTap: () -> Void

    private var count: Int? {
        guard draft.encrypted && draft.encryptionPassword.isEmpty else { return nil }
        guard !draft.autoEncryptDisabledRecipients.isEmpty else { return nil }

        return draft.autoEncryptDisabledRecipients.count
    }

    private let badgeWidth: CGFloat = 16

    var body: some View {
        Button {
            didTap()
        } label: {
            draft.encrypted ?
                MailResourcesAsset.lockSquare.swiftUIImage : MailResourcesAsset.unlockSquare.swiftUIImage
        }
        .foregroundColor(draft.encrypted ? Color.accentColor : MailResourcesAsset.textSecondaryColor.swiftUIColor)
        .overlay {
            if count != nil || isLoadingRecipientsAutoEncrypt {
                Circle()
                    .fill(MailResourcesAsset.orangeColor.swiftUIColor)
                    .overlay {
                        if let count {
                            Text(count, format: .cappedCount(maximum: 9, placement: .before))
                                .font(.system(size: 8))
                                .foregroundStyle(MailResourcesAsset.backgroundTertiaryColor.swiftUIColor)
                                .animation(.default, value: count)
                        } else if isLoadingRecipientsAutoEncrypt {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 2)
                        }
                    }
                    .frame(width: badgeWidth)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .offset(x: badgeWidth / 2)
            }
        }
        .task(id: "\(draft.encrypted)-\(draft.allRecipients.count)") {
            guard draft.encrypted, !draft.allRecipients.isEmpty else { return }

            isLoadingRecipientsAutoEncrypt = true

            try? await mailboxManager.updateRecipientsAutoEncrypt(draft: draft)

            isLoadingRecipientsAutoEncrypt = false
        }
    }
}

#Preview {
    EncryptionButton(draft: Draft()) {}
}
