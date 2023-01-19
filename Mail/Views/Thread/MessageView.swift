/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import InfomaniakCore
import MailCore
import MailResources
import RealmSwift
import Shimmer
import SwiftUI

struct MessageView: View {
    @ObservedRealmObject var message: Message
    @EnvironmentObject var mailboxManager: MailboxManager
    @State var isHeaderExpanded = false
    @State var isMessageExpanded: Bool

    init(message: Message, isMessageExpanded: Bool = false) {
        self.message = message
        self.isMessageExpanded = isMessageExpanded
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(MailResourcesAsset.backgroundColor.swiftUiColor)
            VStack(spacing: 16) {
                MessageHeaderView(
                    message: message,
                    isHeaderExpanded: $isHeaderExpanded,
                    isMessageExpanded: $isMessageExpanded
                )
                .padding(.horizontal, 16)

                if isMessageExpanded {
                    if !message.attachments.filter { $0.contentId == nil }.isEmpty {
                        AttachmentsView(message: message)
                    }
                    MessageBodyView(message: message)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, isMessageExpanded ? 8 : 16)
            .task {
                if self.message.shouldComplete {
                    await fetchMessage()
                }
            }
        }
        .padding(.bottom, 8)
    }

    @MainActor private func fetchMessage() async {
        await tryOrDisplayError {
            try await mailboxManager.message(message: message)
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageView(message: PreviewHelper.sampleMessage)

            MessageView(message: PreviewHelper.sampleMessage, isMessageExpanded: true)
        }
        .previewLayout(.sizeThatFits)
    }
}
