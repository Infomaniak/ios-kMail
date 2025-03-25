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

struct MessageSpamHeaderView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ObservedRealmObject var message: Message
    @ObservedRealmObject var mailbox: Mailbox

    @State private var isButtonLoading = false

    var body: some View {
        let spamType = spamTypeFor(message: message)
        if spamType != .none {
            MessageHeaderActionView(
                icon: spamType.icon,
                iconColor: spamType.iconColor,
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
        let spamType = spamTypeFor(message: message)
        Task {
            switch spamType {
            case .none:
                return
            case .moveInSpam:
                _ = try? await mailboxManager.move(messages: [message], to: .spam)
            case .enableSpamFilter:
                _ = try? await mailboxManager.activateSpamFilter()
            case .unblockRecipient(let sender):
                try await mailboxManager.unblockSender(sender: sender)
            }

            isButtonLoading = false
        }
    }

    private func spamTypeFor(message: Message) -> SpamHeaderType {
        if message.folder?.role != .spam {
            if message.isSpam && !isSenderApproved(sender: message.from.first?.email) {
                if mailbox.isSpamFilter {
                    return .moveInSpam
                } else {
                    return .enableSpamFilter
                }
            }
        }

        if message.folder?.role == .spam {
            if let sender = message.from.first, !message.isSpam && isSenderBlocked(sender: sender.email) {
                return .unblockRecipient(sender.email)
            }
        }

        return .none
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
    MessageSpamHeaderView(message: PreviewHelper.sampleMessage, mailbox: PreviewHelper.sampleMailboxManager.mailbox)
}
