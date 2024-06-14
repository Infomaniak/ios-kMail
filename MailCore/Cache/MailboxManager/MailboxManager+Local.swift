/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import Foundation

public extension MailboxManager {
    enum UpdateType {
        case seen
        case star

        func update(message: Message, with value: Bool) {
            switch self {
            case .seen:
                message.seen = value
            case .star:
                message.flagged = value
            }
        }

        func update(thread: Thread) {
            switch self {
            case .seen:
                thread.updateUnseenMessages()
            case .star:
                thread.updateFlagged()
            }
        }
    }

    func updateLocally(_ type: UpdateType, value: Bool, messages: [Message]) async {
        try? writeTransaction { writableRealm in
            var updateThreads = Set<Thread>()

            for message in messages {
                guard let liveMessage = writableRealm.object(ofType: Message.self, forPrimaryKey: message.uid) else {
                    continue
                }

                type.update(message: liveMessage, with: value)

                for thread in liveMessage.threads {
                    updateThreads.insert(thread)
                }
            }

            for thread in updateThreads {
                guard let liveThread = writableRealm.object(ofType: Thread.self, forPrimaryKey: thread.uid) else {
                    continue
                }

                type.update(thread: liveThread)
            }
        }
    }

    func markMovedLocally(_ movedLocally: Bool, threads: [Thread]) async {
        try? writeTransaction { writableRealm in
            for thread in threads {
                guard let liveThread = writableRealm.object(ofType: Thread.self, forPrimaryKey: thread.uid) else {
                    continue
                }

                liveThread.isMovedOutLocally = movedLocally
            }
        }
    }
}
