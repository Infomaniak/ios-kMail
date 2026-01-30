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

import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct EncryptionButton: View {
    static let encryptionEnabledForeground = MailResourcesAsset.sovereignBlueColor.swiftUIColor

    @EnvironmentObject private var mailboxManager: MailboxManager

    @LazyInjectService private var snackbarPresenter: IKSnackBarPresentable

    @State private var isShowingEncryptAdPanel = false
    @State private var isShowingEncryptPasswordPanel = false

    @State private var isLoadingRecipientsAutoEncrypt = false

    @State private var justActivatedEncryption = false
    @State private var canShowIncompleteUserSnackbar = true

    @Binding var isShowingEncryptStatePanel: Bool

    let draft: Draft

    private var count: Int? {
        guard draft.encrypted && draft.encryptionPassword.isEmpty else { return nil }
        guard !draft.autoEncryptDisabledRecipients.isEmpty else { return nil }

        return draft.autoEncryptDisabledRecipients.count
    }

    private let badgeWidth: CGFloat = 16

    var body: some View {
        Button(action: didTapEncrypt) {
            Label {
                Text(MailResourcesStrings.Localizable.encryptedStatePanelTitle)
            } icon: {
                draft.encrypted ?
                    MailResourcesAsset.lockSquare.swiftUIImage : MailResourcesAsset.unlockSquare.swiftUIImage
            }
            .labelStyle(.iconOnly)
            .overlay {
                if count != nil || isLoadingRecipientsAutoEncrypt {
                    Circle()
                        .fill(MailResourcesAsset.orangeColor.swiftUIColor)
                        .overlay {
                            if let count {
                                Text(count, format: .cappedCount(maximum: 9, placement: .before))
                                    .monospacedDigit()
                                    .font(.system(size: 8))
                                    .foregroundStyle(MailResourcesAsset.backgroundTertiaryColor.swiftUIColor)
                                    .animation(.default, value: count)
                            } else if isLoadingRecipientsAutoEncrypt {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 2)
                            }
                        }
                        .frame(width: badgeWidth)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .offset(x: badgeWidth / 2)
                }
            }
        }
        .foregroundColor(draft.encrypted ? Self.encryptionEnabledForeground : MailResourcesAsset.textSecondaryColor.swiftUIColor)
        .task(id: "\(draft.encrypted)-\(draft.allRecipients.count)") {
            guard draft.encrypted else { return }
            let recipientsCount = await loadRecipientsAutoEncryptIfNeeded()
            showEncryptionSnackbarIfNeeded(for: recipientsCount)
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
        justActivatedEncryption = true
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
        snackbarPresenter.show(message: MailResourcesStrings.Localizable.encryptedMessageSnackbarEncryptionDisabled)

        canShowIncompleteUserSnackbar = true

        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .encryption, name: "disable")
    }

    private func showEncryptionSnackbarIfNeeded(for recipientsCount: Int) {
        let action = IKSnackBar.Action(title: MailResourcesStrings.Localizable.encryptedMessageSnackbarProtectAction) {
            isShowingEncryptPasswordPanel = true
        }

        if recipientsCount == 1 && canShowIncompleteUserSnackbar {
            snackbarPresenter.show(
                message: MailResourcesStrings.Localizable.encryptedMessageIncompleteUser(recipientsCount),
                action: action
            )
            canShowIncompleteUserSnackbar = false
        } else if justActivatedEncryption {
            if recipientsCount > 0 {
                snackbarPresenter.show(
                    message: MailResourcesStrings.Localizable.encryptedMessageIncompleteUser(recipientsCount),
                    action: action
                )
            } else {
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.encryptedMessageSnackbarEncryptionActivated)
            }
        }

        justActivatedEncryption = false
    }

    private func loadRecipientsAutoEncryptIfNeeded() async -> Int {
        guard !draft.allRecipients.isEmpty else { return 0 }
        isLoadingRecipientsAutoEncrypt = true
        let recipientsCount = try? await mailboxManager.updateRecipientsAutoEncrypt(draft: draft)
        isLoadingRecipientsAutoEncrypt = false
        return recipientsCount ?? 0
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isShowingEncryptStatePanel = false
    EncryptionButton(isShowingEncryptStatePanel: $isShowingEncryptStatePanel, draft: Draft())
}
