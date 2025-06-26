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
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI
import WrappingHStack

struct EncryptionPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var mailboxManager: MailboxManager
    @ObservedRealmObject var draft: Draft

    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: IKPadding.huge) {
                        VStack(alignment: .leading, spacing: IKPadding.small) {
                            Text(MailResourcesStrings.Localizable.encryptedMessageAddPasswordInformation)
                                .textStyle(.bodySecondary)

                            Button {
                                if let url = URL(string: "https://faq.infomaniak.com/1582") {
                                    openURL(url)
                                }
                            } label: {
                                Text(MailResourcesStrings.Localizable.moreInfo)
                                    .font(MailTextStyle.bodyMedium.font)
                            }
                        }

                        VStack(alignment: .leading, spacing: IKPadding.small) {
                            Text(MailResourcesStrings.Localizable.encryptedMessagePasswordConcernedUserTitle)
                                .textStyle(.bodyMedium)

                            WrappingHStack {
                                ForEach(draft.autoEncryptDisabledRecipients, id: \.email) { recipient in
                                    RecipientChipLabelView(recipient: recipient)
                                }
                                .environmentObject(mailboxManager)
                            }
                        }
                    }
                    .padding(value: .medium)
                }
                .navigationTitle(MailResourcesStrings.Localizable.encryptedPasswordProtectionTitle)
                .navigationBarTitleDisplayMode(.inline)
            }

            VStack(alignment: .leading, spacing: IKPadding.small) {
                Text(MailResourcesStrings.Localizable.encryptedMessagePasswordLabel)
                    .textStyle(.bodySmall)

                HStack {
                    TextField(MailResourcesStrings.Localizable.enterPasswordTitle, text: $draft.encryptionPassword)

                    Button {
                        // Generate password
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

                Button {
                    UIPasteboard.general.string = draft.encryptionPassword
                    dismiss()
                } label: {
                    Label {
                        Text(MailResourcesStrings.Localizable.buttonCopy)
                    } icon: {
                        MailResourcesAsset.duplicate.swiftUIImage
                            .resizable()
                            .frame(width: 16, height: 16)
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
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(value: .medium)
        }
        .tint(MailResourcesAsset.sovereignBlueColor.swiftUIColor)
        .onAppear {
            if draft.encryptionPassword.isEmpty, let liveDraft = draft.thaw() {
                try? liveDraft.realm?.write {
                    liveDraft.encryptionPassword = generateStrongSecurePassword()
                }
            }
        }
    }

    func generateStrongSecurePassword() -> String {
        let length = 16

        let lowercase = Array("abcdefghijklmnopqrstuvwxyz")
        let uppercase = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let digits = Array("0123456789")
        let symbols = Array("!@#$%^&*()-_=+[]{}|;:,.<>?")
        let all = lowercase + uppercase + digits + symbols

        var randomGenerator = SystemRandomNumberGenerator()

        var passwordChars: [Character] = [
            lowercase.randomElement(using: &randomGenerator)!,
            uppercase.randomElement(using: &randomGenerator)!,
            digits.randomElement(using: &randomGenerator)!,
            symbols.randomElement(using: &randomGenerator)!
        ]

        for _ in 4 ..< length {
            passwordChars.append(all.randomElement(using: &randomGenerator)!)
        }

        passwordChars.shuffle(using: &randomGenerator)

        return String(passwordChars)
    }
}

#Preview {
    EncryptionPasswordView(draft: Draft())
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
