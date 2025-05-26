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

    @ObservedRealmObject var message: Message
    @ObservedRealmObject var mailbox: Mailbox

    @Binding var displayContentBlockedActionView: Bool

    private var isRemoteContentBlocked: Bool {
        return (UserDefaults.shared.displayExternalContent == .askMe || message.folder?.role == .spam)
            && !message.localSafeDisplay
    }

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
        let spamType = spamTypeFor(message: message)
        if let spamType {
            MessageHeaderActionView(
                icon: spamType.icon,
                message: spamType.message,
                isFirst: true
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

        if isRemoteContentBlocked && displayContentBlockedActionView {
            MessageHeaderActionView(
                icon: MailResourcesAsset.emailActionWarning.swiftUIImage,
                message: MailResourcesStrings.Localizable.alertBlockedImagesDescription,
                isFirst: spamType == nil
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
                isFirst: spamType == nil && !(isRemoteContentBlocked && displayContentBlockedActionView),
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
        let spamType = spamTypeFor(message: message)
        Task {
            switch spamType {
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

    private func spamTypeFor(message: Message) -> SpamHeaderType? {
        if message.folder?.role != .spam,
           message.isSpam && !isSenderApproved(sender: message.from.first?.email) {
            if mailbox.isSpamFilter {
                return .moveInSpam
            } else {
                return .enableSpamFilter
            }
        }

        if message.folder?.role == .spam,
           let sender = message.from.first, !message.isSpam && isSenderBlocked(sender: sender.email) {
            return .unblockRecipient(sender.email)
        }

        return nil
    }

    private func isSenderApproved(sender: String?) -> Bool {
        guard let sender,
              let sendersRestrictions = mailbox.sendersRestrictions else {
            return false
        }
        return sendersRestrictions.authorizedSenders.contains { $0.email == sender }
    }

    private func isSenderBlocked(sender: String?) -> Bool {
        guard let sender,
              let sendersRestrictions = mailbox.sendersRestrictions else {
            return false
        }
        return sendersRestrictions.blockedSenders.contains { $0.email == sender }
    }
}

#Preview {
    MessageBannerHeaderView(
        message: PreviewHelper.sampleMessage,
        mailbox: PreviewHelper.sampleMailbox,
        displayContentBlockedActionView: .constant(true)
    )
}
