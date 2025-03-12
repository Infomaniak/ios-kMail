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
import SwiftUI

struct MessageSpamHeaderView: View {
    @InjectService private var accountManager: AccountManager

    private let mailboxManager: MailboxManager
    private let message: Message
    @ObservedObject private var mailbox: Mailbox

    @State private var spamType: SpamHeaderType = .none
    @State private var isButtonLoading = false

    init(message: Message, mailboxManager: MailboxManager) {
        self.message = message
        self.mailboxManager = mailboxManager

        @InjectService var mailboxInfosManager: MailboxInfosManager
        mailbox = mailboxManager.mailbox.fresh(transactionable: mailboxInfosManager) ?? mailboxManager.mailbox

        _spamType = State(initialValue: spamTypeFor(message: message))
    }

    var body: some View {
        if spamType != .none {
            MessageHeaderActionView(
                icon: MailResourcesAsset.warningFill.swiftUIImage,
                iconColor: MailResourcesAsset.orangeColor.swiftUIColor,
                message: spamType.message
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
    }

    private func action() {
        isButtonLoading = true
        Task {
            switch spamType {
            case .none:
                return
            case .moveInSpam:
                _ = try? await mailboxManager.move(messages: [message], to: .spam)
            case .enableSpamFilter:
                // Enable spam filter
                return
            case .unblockRecipient(let sender):
                try await mailboxManager.unblockSender(sender: sender)
                spamType = .none
            }
            isButtonLoading = false
        }
    }

    private func spamTypeFor(message: Message) -> SpamHeaderType {
        if message.folder?.role != .spam {
            if message.isSpam && !isSenderApproved(sender: message.from.first?.email) {
                // 1a - Filtre spam desactivé
                return .enableSpamFilter

                // 1b - Filtre spam activé
                return .moveInSpam
            }
        }

        // 2
        if message.folder?.role == .spam {
            if let sender = message.from.first, !message.isSpam && isSenderBlocked(sender: sender.email) {
                return .unblockRecipient(sender.email)
            }
        }

        return .none
    }

    private func isSenderApproved(sender: String?) -> Bool {
        guard let sender, let sendersRestrictions = mailbox.sendersRestrictions else {
            return false
        }
        return sendersRestrictions.authorizedSenders.contains { $0.email == sender }
    }

    private func isSenderBlocked(sender: String?) -> Bool {
        guard let sender, let sendersRestrictions = mailbox.sendersRestrictions else {
            return false
        }
        return sendersRestrictions.blockedSenders.contains { $0.email == sender }
    }
}

#Preview {
    MessageSpamHeaderView(message: PreviewHelper.sampleMessage, mailboxManager: PreviewHelper.sampleMailboxManager)
}

enum SpamHeaderType: Equatable {
    case none
    case moveInSpam
    case enableSpamFilter
    case unblockRecipient(String)

    var message: String {
        switch self {
        case .none:
            ""
        case .moveInSpam:
            "Ce message est considéré comme du spam. Nous vous recommandons de le déplacer dans le dossier \"Spam\"."
        case .enableSpamFilter:
            "Ce message est considéré comme du spam. Par sécurité, nous vous recommandons d'activer le filtre anti-spam."
        case .unblockRecipient(let recipient):
            "Ce message figure dans les spam car \(recipient) se trouve dans la liste des expéditeurs bloqués."
        }
    }

    var buttonTitle: String {
        switch self {
        case .none:
            ""
        case .moveInSpam:
            "Déplacer dans Spam"
        case .enableSpamFilter:
            "Activer le filtre"
        case .unblockRecipient:
            "Débloquer"
        }
    }
}
