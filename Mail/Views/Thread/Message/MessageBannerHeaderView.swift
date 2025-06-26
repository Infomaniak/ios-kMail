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

    var body: some View {
        ForEach(banners) { banner in
            let showBottomSeparator = banners.shouldShowBottomSeparator(for: banner)
            switch banner {
            case .displayContent:
                MessageHeaderActionView(
                    icon: MailResourcesAsset.emailActionWarning.swiftUIImage,
                    message: MailResourcesStrings.Localizable.alertBlockedImagesDescription,
                    showBottomSeparator: showBottomSeparator
                ) {
                    Button(MailResourcesStrings.Localizable.alertBlockedImagesDisplayContent) {
                        withAnimation {
                            $message.localSafeDisplay.wrappedValue = true
                        }
                    }
                }
            case .encrypted:
                MessageEncryptionHeaderView(message: message, mailbox: mailbox)
            case .schedule(let scheduleDate, let draftResource):
                MessageScheduleHeaderView(
                    scheduleDate: scheduleDate,
                    draftResource: draftResource,
                    showBottomSeparator: showBottomSeparator
                )
            case .spam(let spamType):
                MessageHeaderActionView(
                    icon: spamType.icon,
                    message: spamType.message,
                    showBottomSeparator: showBottomSeparator
                ) {
                    Button {
                        action(spamType: spamType)
                    } label: {
                        Text(spamType.buttonTitle)
                    }
                    .disabled(isButtonLoading)
                    .ikButtonLoading(isButtonLoading)
                }
            }
        }
    }

    private func action(spamType: SpamHeaderType) {
        isButtonLoading = true
        Task {
            switch spamType {
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
}

#Preview {
    MessageBannerHeaderView(
        banners: [],
        message: PreviewHelper.sampleMessage,
        mailbox: PreviewHelper.sampleMailbox
    )
}
