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

enum MessageExpansionType: Equatable {
    case expanded
    case collapsed
    case superCollapsed
    case firstSuperCollapsed(Int)
}

struct MessageListView: View {
    @StateObject private var messagesWorker: MessagesWorker
    @State private var messageExpansion = [String: MessageExpansionType]()

    @Binding var messagesToExpand: [String]
    let messages: [Message]

    init(messages: [Message], mailboxManager: MailboxManager, messagesToExpand: Binding<[String]>) {
        _messagesWorker = StateObject(wrappedValue: MessagesWorker(mailboxManager: mailboxManager))
        self.messages = messages
        _messagesToExpand = messagesToExpand
    }

    var body: some View {
        ScrollViewReader { proxy in
            LazyVStack(spacing: 0) {
                ForEach(messages, id: \.uid) { message in
                    ZStack {
                        if case .firstSuperCollapsed(let count) = messageExpansion[message.uid] {
                            SuperCollapsedView(count: count) {
                                uncollapse(from: message.uid)
                            }
                        } else if messageExpansion[message.uid] != .superCollapsed {
                            VStack(spacing: 0) {
                                MessageView(threadForcedExpansion: $messageExpansion, message: message)
                                if divider(for: message) {
                                    IKDivider(type: .full)
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                computeExpansion(from: messages)

                guard messages.count > 1, let firstExpandedUid = firstExpanded()?.uid else {
                    return
                }

                // TODO: listen for last message `.isFullyLoaded` to be exact
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        proxy.scrollTo(firstExpandedUid, anchor: .top)
                    }
                }
            }
            .environmentObject(messagesWorker)
            .id(messages.id)
        }
    }

    private func computeExpansion(from messageList: [Message]) {
        var toSuperCollapse = [String]()

        for message in messageList {
            if messagesToExpand.contains(message.uid) {
                messageExpansion[message.uid] = .expanded
            } else {
                messageExpansion[message.uid] = expansion(for: message, from: messageList)
            }

            guard message != messageList.first && message != messageList.last else { continue }
            guard messageExpansion[message.uid] != .expanded else {
                superCollapseIfNeeded(toSuperCollapse)
                toSuperCollapse.removeAll()
                continue
            }

            toSuperCollapse.append(message.uid)
        }

        superCollapseIfNeeded(toSuperCollapse)
    }

    private func superCollapseIfNeeded(_ ids: [String]) {
        guard ids.count > 2 else { return }

        for id in ids {
            messageExpansion[id] = .superCollapsed
        }
        if let firstId = ids.first {
            messageExpansion[firstId] = .firstSuperCollapsed(ids.count)
        }
    }

    private func uncollapse(from id: String) {
        var toUncollapse = [String]()

        for message in messages {
            if message.uid == id {
                toUncollapse.append(message.uid)
            } else {
                guard !toUncollapse.isEmpty else {
                    // Did not start uncollapsing
                    continue
                }
                guard messageExpansion[message.uid] == .superCollapsed else {
                    // Finished uncollapsing
                    break
                }
                toUncollapse.append(message.uid)
            }
        }

        withAnimation {
            for id in toUncollapse {
                messageExpansion[id] = .collapsed
            }
        }
    }

    private func divider(for message: Message) -> Bool {
        if message != messages.last {
            guard let index = messages.firstIndex(of: message),
                  index + 1 < messages.count else { return true }
            if case .firstSuperCollapsed = messageExpansion[messages[index + 1].uid] {
                return false
            }
            return true
        }
        return false
    }

    private func isExpanded(message: Message, from messageList: [Message]) -> Bool {
        return ((messageList.last?.uid == message.uid) && !message.isDraft) || !message.seen
    }

    /// Function used to give a first value to a message expansion before trying to superCollapse it
    /// Return `expanded` or `collapsed`
    /// Not `superCollapsed`
    private func expansion(for message: Message, from messageList: [Message]) -> MessageExpansionType {
        return isExpanded(message: message, from: messageList) ? .expanded : .collapsed
    }

    private func firstExpanded() -> Message? {
        return messages.first { isExpanded(message: $0, from: messages) }
    }
}
