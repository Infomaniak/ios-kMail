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
import RealmSwift
import SwiftUI

struct EncryptionButton: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingEncryptAdPanel = false
    @State private var isShowingEncryptPasswordPanel = false

    @State private var isLoadingRecipientsAutoEncrypt = false

    let draft: Draft
    @Binding var isShowingEncryptStatePanel: Bool

    private var count: Int? {
        guard draft.encrypted && draft.encryptionPassword.isEmpty else { return nil }
        guard !draft.autoEncryptDisabledRecipients.isEmpty else { return nil }

        return draft.autoEncryptDisabledRecipients.count
    }

    private let badgeWidth: CGFloat = 16

    var body: some View {
        Button {
            didTapEncrypt()
        } label: {
            draft.encrypted ?
                MailResourcesAsset.lockSquare.swiftUIImage : MailResourcesAsset.unlockSquare.swiftUIImage
        }
        .foregroundColor(draft.encrypted ?
            MailResourcesAsset.sovereignBlueColor.swiftUIColor : MailResourcesAsset.textSecondaryColor.swiftUIColor)
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
        .sheet(isPresented: $isShowingEncryptAdPanel) {
            EncryptionAdView { enableEncryption() }
        }
        .sheet(isPresented: $isShowingEncryptPasswordPanel) {
            EncryptionPasswordView(draft: draft)
                .environmentObject(mailboxManager) // For macOS - SwiftUI seems to have issues passing the environment (again)
        }
        .mailFloatingPanel(isPresented: $isShowingEncryptStatePanel) {
            EncryptionStateView(
                password: draft.encryptionPassword,
                autoEncryptDisableCount: draft.autoEncryptDisabledRecipients.count,
                isShowingPasswordView: $isShowingEncryptPasswordPanel
            ) {
                disableEncryption()
            }
        }
    }

    private func didTapEncrypt() {
        if !draft.encrypted {
            if UserDefaults.shared.shouldPresentEncryptAd {
                isShowingEncryptAdPanel = true
            } else {
                enableEncryption()
            }
        } else {
            isShowingEncryptStatePanel = true
        }
    }

    private func enableEncryption() {
        guard let liveDraft = draft.thaw() else { return }
        try? liveDraft.realm?.write {
            liveDraft.encrypted = true
        }
    }

    private func disableEncryption() {
        guard let liveDraft = draft.thaw() else { return }
        try? liveDraft.realm?.write {
            liveDraft.encrypted = false
            liveDraft.encryptionPassword = ""
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isShowingEncryptStatePanel = false
    EncryptionButton(draft: Draft(), isShowingEncryptStatePanel: $isShowingEncryptStatePanel)
}
