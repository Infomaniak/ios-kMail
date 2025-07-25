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

import DesignSystem
import InfomaniakCoreSwiftUI
import MailCoreUI
import MailResources
import SwiftUI

struct EncryptionStateView: View {
    @Environment(\.dismiss) private var dismiss

    let password: String
    let autoEncryptDisableCount: Int
    @Binding var isShowingPasswordView: Bool
    let disableEncryption: () -> Void

    private var isEncryptionEnabled: Bool {
        autoEncryptDisableCount == 0 || !password.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.medium) {
            VStack(alignment: .leading, spacing: IKPadding.mini) {
                HStack {
                    MailResourcesAsset.shieldLock.swiftUIImage
                        .foregroundStyle(MailResourcesAsset.sovereignBlueColor.swiftUIColor)

                    Text(MailResourcesStrings.Localizable.encryptedStatePanelTitle)

                    Text(isEncryptionEnabled ?
                        MailResourcesStrings.Localizable.settingsEnabled :
                        MailResourcesStrings.Localizable.encryptedStatePanelStatePartialLabel)
                        .padding(value: .micro)
                        .foregroundStyle(MailResourcesAsset.onTagExternalColor.swiftUIColor)
                        .background(isEncryptionEnabled ?
                            MailResourcesAsset.greenColor.swiftUIColor : MailResourcesAsset.yellowColor.swiftUIColor)
                        .clipShape(RoundedRectangle(cornerRadius: IKRadius.small))
                }

                Text(isEncryptionEnabled ?
                    MailResourcesStrings.Localizable.encryptedStatePanelEnable :
                    "\(MailResourcesStrings.Localizable.encryptedMessageIncompleteUser(autoEncryptDisableCount)) \(MailResourcesStrings.Localizable.encryptedStatePanelIncomplete)")
                    .textStyle(.bodySecondary)
            }

            if autoEncryptDisableCount > 0 {
                Divider()

                Button {
                    dismiss()
                    isShowingPasswordView = true
                } label: {
                    Label {
                        Text(password.isEmpty ?
                            MailResourcesStrings.Localizable.encryptedMessageAddPasswordButton :
                            MailResourcesStrings.Localizable.encryptedMessageUpdatePasswordButton)
                    } icon: {
                        MailResourcesAsset.passwordLock.swiftUIImage
                            .foregroundStyle(MailResourcesAsset.sovereignBlueColor.swiftUIColor)
                    }
                }
                .buttonStyle(.plain)
            }

            Divider()

            Button {
                disableEncryption()
                dismiss()
            } label: {
                Label {
                    Text(MailResourcesStrings.Localizable.encryptedMessageDisableEncryptionButton)
                } icon: {
                    MailResourcesAsset.unlockSquare.swiftUIImage
                        .foregroundStyle(MailResourcesAsset.sovereignBlueColor.swiftUIColor)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(value: .medium)
    }
}

#Preview {
    EncryptionStateView(password: "", autoEncryptDisableCount: 1, isShowingPasswordView: .constant(false)) {}
}
