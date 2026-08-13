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

import AppIntents
import Foundation
import InfomaniakConcurrency
import InfomaniakDI
import MailCore
import Nuke

@available(iOS 18.0, *)
@AppEntity(schema: .mail.account)
public struct MailAccountEntity: IndexedEntity {
    public static let defaultQuery = MailAccountEntityQuery()

    // MARK: Properties

    public let id: String

    public var name: String
    public var emailAddress: String
    public var avatarData: Data?

    public var displayRepresentation: DisplayRepresentation {
        if let avatarData {
            return DisplayRepresentation(title: "\(emailAddress)", image: .init(data: avatarData))
        }
        return DisplayRepresentation(title: "\(emailAddress)", image: .init(systemName: "person"))
    }

    public init(id: String, name: String, emailAddress: String, avatarData: Data? = nil) {
        self.id = id
        self.name = name
        self.emailAddress = emailAddress
        self.avatarData = avatarData
    }

    // MARK: Query

    public struct MailAccountEntityQuery: EntityQuery {
        public init() {}

        private func fetchAvatarData(for mailbox: Mailbox) async -> Data? {
            @InjectService var accountManager: AccountManager
            guard let userProfile = await accountManager.userProfileStore.getUserProfile(id: mailbox.userId),
                  let avatarString = userProfile.avatar,
                  let avatarURL = URL(string: avatarString) else {
                return nil
            }
            return try? await ImagePipeline.shared.image(for: ImageRequest(url: avatarURL)).pngData()
        }

        public func entities(for identifiers: [MailAccountEntity.ID]) async throws -> [MailAccountEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager

            let idSet = Set(identifiers)
            let matchingMailboxes = mailboxInfosManager.getMailboxes().filter { idSet.contains($0.objectId) }
            return await matchingMailboxes.asyncMap { mailbox in
                await MailAccountEntity(
                    id: mailbox.objectId,
                    name: mailbox.mailbox,
                    emailAddress: mailbox.email,
                    avatarData: fetchAvatarData(for: mailbox)
                )
            }
        }

        public func suggestedEntities() async throws -> [MailAccountEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager

            return await mailboxInfosManager.getMailboxes().asyncMap { mailbox in
                await MailAccountEntity(
                    id: mailbox.objectId,
                    name: mailbox.mailbox,
                    emailAddress: mailbox.email,
                    avatarData: fetchAvatarData(for: mailbox)
                )
            }
        }
    }
}
