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
@testable import Infomaniak_Mail
@testable import InfomaniakCore
@testable import InfomaniakDI
@testable import InfomaniakLogin
@testable import MailCore

public enum MockingConfiguration {
    /// Full app, able to perform network calls.
    /// The app is unaware of the tests
    /// Perfect for UItests
    case realApp

    // TODO: make sure only the minimal set of real object is set in DI
    /// Minimal real objects
    /// Mocked navigation and networking stack…
    case minimal
}

/// Something to help using the DI in the test target
public enum MockingHelper {
    /// Register "real" instances like in the app
    static func registerConcreteTypes(configuration: MockingConfiguration, extraFactories: [Factory] = []) {
        var factories: [Factory] = []

        switch configuration {
        case .realApp:
            factories += TargetAssembly.getTargetServices() + TargetAssembly.getCommonServices()

        case .minimal:
            // TODO: Add mocks
            break
        }

        // override with extra
        factories += extraFactories

        for factory in factories {
            SimpleResolver.sharedResolver.store(factory: factory)
        }
    }

    /// Clear stored types in DI
    static func clearRegisteredTypes() {
        SimpleResolver.sharedResolver.removeAll()
    }

    static func getTestMailboxManager() -> MailboxManager {
        let token = ApiToken(accessToken: Env.token,
                             expiresIn: Int.max,
                             refreshToken: "",
                             scope: "",
                             tokenType: "",
                             userId: Env.userId,
                             expirationDate: Date(timeIntervalSinceNow: TimeInterval(Int.max)))
        let mailbox = Mailbox()
        mailbox.userId = token.userId
        mailbox.mailboxId = Env.mailboxId
        mailbox.uuid = Env.mailboxUuid
        let apiFetcher = MailApiFetcher(token: token, delegate: MCKTokenDelegate())
        let contactManager = ContactManager(userId: Env.userId, apiFetcher: MailApiFetcher())

        let mailboxManager = MailboxManager(
            mailbox: mailbox,
            apiFetcher: apiFetcher,
            contactManager: contactManager
        )
        return mailboxManager
    }
}
