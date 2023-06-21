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

import MailCore
import MailResources
import RealmSwift
import SwiftUI

final class MessageSelectionViewModel: ObservableObject {
    @Published var messages: [Message]

    var messageExpended: [String: Bool] = [:]

    init(messages: [Message], messageExpended: [String: Bool] = [:]) {
        self.messages = messages
        self.messageExpended = messageExpended
    }

    func changeExpanded(forMessageUid uid: String, isExpanded: Bool) {
        messageExpended[uid] = isExpanded
    }
    
    func expanded(forMessage message: Message) -> Bool {
        if let value = messageExpended[message.uid] {
            print("••expanded(forMessage:) cached : \(value)")
            return value
        } else {
            let isExpanded = messages.isExpanded(message)
            print("••expanded(forMessage:) computed : \(isExpanded)")
            changeExpanded(forMessageUid: message.uid, isExpanded: isExpanded)
            return isExpanded
        }
    }
}

struct MessageListView: View {
    @ObservedObject var viewModel: MessageSelectionViewModel

    init(messages: [Message]) {
        viewModel = MessageSelectionViewModel(messages: messages)
    }

    var body: some View {
        List {
            ForEach(viewModel.messages, id: \.uid) { message in
                VStack {
                    MessageView(message: message, viewModel: viewModel)
                    if viewModel.messages.isLast(message) {
                        IKDivider()
                    }
                }.listRowSeparator(.hidden)
            }
        }.listStyle(.inset)
    }
}
