/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import MailCore
import MailCoreUI
import SwiftUI

struct MessageListView: View {
    let messages: [Message]

    @State private var messageExpansion = [String: Bool]()

    var body: some View {
        ScrollViewReader { proxy in
            LazyVStack(spacing: 0) {
                ForEach(messages, id: \.uid) { message in
                    VStack(spacing: 0) {
                        MessageView(
                            message: message,
                            isMessageExpanded: isExpanded(message: message, from: messages),
                            threadForcedExpansion: $messageExpansion
                        )
                        if message != messages.last {
                            IKDivider(type: .full)
                        }
                    }
                    .id(message.uid)
                }
            }
            .onAppear {
                computeExpansion(from: messages)

                guard messages.count > 1,
                      let firstExpandedUid = firstExpanded()?.uid else {
                    return
                }

                // TODO: listen for last message `.isFullyLoaded` to be exact
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        proxy.scrollTo(firstExpandedUid, anchor: .top)
                    }
                }
            }
            .id(messages.id)
        }
    }

    private func computeExpansion(from messageList: [Message]) {
        for message in messageList {
            guard messageExpansion[message.uid] != true else { continue }
            messageExpansion[message.uid] = isExpanded(message: message, from: messageList)
        }
    }

    private func isExpanded(message: Message, from messageList: [Message]) -> Bool {
        return ((messageList.last?.uid == message.uid) && !message.isDraft) || !message.seen
    }

    private func firstExpanded() -> Message? {
        return messages.first { isExpanded(message: $0, from: messages) }
    }
}
