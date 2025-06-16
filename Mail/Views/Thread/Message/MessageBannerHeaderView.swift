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

import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct MessageBannerHeaderView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isButtonLoading = false

    let banners: [MessageBanner]

    @ObservedRealmObject var message: Message
    @ObservedRealmObject var mailbox: Mailbox

    private var fromMe: Bool {
        return message.fromMe(currentMailboxEmail: mailbox.email)
    }

    private var encryptionTitle: String {
        guard fromMe else {
            return MailResourcesStrings.Localizable.encryptedMessageReceiverTitle
        }
        return message.encryptionPassword.isEmpty ? MailResourcesStrings.Localizable.encryptedMessageTitle : MailResourcesStrings
            .Localizable.encryptedMessageDescription
    }

    var body: some View {
        if let spamType = banners.spamType {
            MessageHeaderActionView(
                icon: spamType.icon,
                message: spamType.message,
                isLast: banners.isLast(messageBanner: .spam(spamType: spamType))
            ) {
                Button {
                    action()
                } label: {
                    Text(spamType.buttonTitle)
                }
                .buttonStyle(.ikBorderless(isInlined: true))
                .controlSize(.small)
                .disabled(isButtonLoading)
                .ikButtonLoading(isButtonLoading)
            }
        }

        if banners.contains(where: { $0 == .displayContent }) {
            MessageHeaderActionView(
                icon: MailResourcesAsset.emailActionWarning.swiftUIImage,
                message: MailResourcesStrings.Localizable.alertBlockedImagesDescription,
                isLast: banners.isLast(messageBanner: .displayContent)
            ) {
                Button(MailResourcesStrings.Localizable.alertBlockedImagesDisplayContent) {
                    withAnimation {
                        $message.localSafeDisplay.wrappedValue = true
                    }
                }
                .buttonStyle(.ikBorderless(isInlined: true))
                .controlSize(.small)
            }
        }

        if message.encrypted {
            MessageHeaderActionView(
                icon: MailResourcesAsset.lockSquare.swiftUIImage,
                message: encryptionTitle,
                isLast: false,
                shouldDisplayActions: fromMe && !message.encryptionPassword.isEmpty
            ) {
                Button(MailResourcesStrings.Localizable.buttonCopyPassword) {
                    @LazyInjectService var snackbarPresenter: SnackBarPresentable
                    UIPasteboard.general.string = message.encryptionPassword
                    snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarPasswordCopied)
                }
            }
        }
    }

    private func action() {
        isButtonLoading = true
        Task {
            switch banners.spamType {
            case .moveInSpam:
                _ = try? await mailboxManager.move(messages: [message], to: .spam)
            case .enableSpamFilter:
                _ = try? await mailboxManager.activateSpamFilter()
            case .unblockRecipient(let sender):
                try await mailboxManager.unblockSender(sender: sender)
            case .none:
                break
            }

            isButtonLoading = false
        }
    }
}

#Preview {
    MessageBannerHeaderView(
        banners: [],
        message: PreviewHelper.sampleMessage,
        mailbox: PreviewHelper.sampleMailbox
    )
}
