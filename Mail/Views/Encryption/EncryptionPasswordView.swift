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
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI
import SwiftUIBackports
import WrappingHStack

struct EncryptionPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @EnvironmentObject private var mailboxManager: MailboxManager

    @InjectService private var matomo: MatomoUtils

    @ObservedRealmObject var draft: Draft

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    VStack(alignment: .leading, spacing: IKPadding.huge) {
                        VStack(alignment: .leading, spacing: IKPadding.small) {
                            Text(MailResourcesStrings.Localizable.encryptedMessageAddPasswordInformation)
                                .textStyle(.bodySecondary)

                            Button {
                                openURL(URLConstants.encryptionFAQ.url)
                                matomo.track(eventWithCategory: .encryption, name: "readFAQ")
                            } label: {
                                Text(MailResourcesStrings.Localizable.moreInfo)
                                    .font(MailTextStyle.bodyMedium.font)
                            }
                        }

                        VStack(alignment: .leading, spacing: IKPadding.small) {
                            Text(MailResourcesStrings.Localizable.encryptedMessagePasswordConcernedUserTitle)
                                .textStyle(.bodyMedium)

                            BackportedFlowLayout(draft.autoEncryptDisabledRecipients,
                                                 verticalSpacing: IKPadding.mini,
                                                 horizontalSpacing: IKPadding.mini) { recipient in
                                RecipientChipLabelView(
                                    recipient: recipient,
                                    type: .encrypted(passwordSecured: false),
                                    removeHandler: nil,
                                    switchFocusHandler: nil
                                )
                            }
                            .environmentObject(mailboxManager)
                        }
                    }
                }
                .padding(value: .medium)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: IKPadding.small) {
                    Text(MailResourcesStrings.Localizable.encryptedMessagePasswordLabel)
                        .textStyle(.bodySmall)

                    HStack {
                        TextField(MailResourcesStrings.Localizable.enterPasswordTitle, text: $draft.encryptionPassword)

                        Button {
                            generatePassword(regenerate: true)
                            matomo.track(eventWithCategory: .encryption, name: "generatePassword")
                        } label: {
                            MailResourcesAsset.passwordGenerate.swiftUIImage
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(MailResourcesAsset.textPrimaryColor.swiftUIColor)
                        }
                    }
                    .padding(value: .small)
                    .background {
                        ZStack {
                            MailResourcesAsset.backgroundColor.swiftUIColor
                                .clipShape(.rect(cornerRadius: IKRadius.small))

                            RoundedRectangle(cornerRadius: IKRadius.small)
                                .stroke(lineWidth: 1)
                                .foregroundColor(MailResourcesAsset.textFieldBorder.swiftUIColor)
                        }
                    }

                    ShareLink(item: draft.encryptionPassword) {
                        Label {
                            Text(MailResourcesStrings.Localizable.buttonShare)
                        } icon: {
                            MailResourcesAsset.squareArrowUp.swiftUIImage
                        }
                    }
                    .disabled(draft.encryptionPassword.isEmpty)
                    .buttonStyle(.ikBorderedProminent)
                    .controlSize(.large)
                    .ikButtonFullWidth(true)
                    .padding(.top, value: .small)
                }
                .padding(.horizontal, value: .medium)
                .padding(.vertical, value: .small)
                .background {
                    MailResourcesAsset.textFieldColor.swiftUIColor
                        .clipShape(.rect(cornerRadius: IKRadius.large))
                }
                .padding(value: .medium)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ToolbarCloseButton(dismissAction: dismiss)
                }
            }
            .navigationTitle(MailResourcesStrings.Localizable.encryptedPasswordProtectionTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .tint(MailResourcesAsset.sovereignBlueColor.swiftUIColor)
        .onAppear {
            generatePassword(regenerate: false)
            matomo.track(eventWithCategory: .encryption, name: "openPasswordView")
        }
    }

    func generatePassword(regenerate: Bool) {
        guard draft.encryptionPassword.isEmpty || regenerate,
              let liveDraft = draft.thaw() else { return }

        let passwordGenerator = SimplePasswordGenerator(passwordLength: 16)
        try? liveDraft.realm?.write {
            liveDraft.encryptionPassword = passwordGenerator.generate()
        }
    }
}

#Preview {
    EncryptionPasswordView(draft: Draft())
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
