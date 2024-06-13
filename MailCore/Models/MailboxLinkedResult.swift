/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

public class MailboxLinkedResult: Codable {
    public var id: Int
    public var mail: String
    public var mailIdn: String
    public var hasValidPassword: Bool
    public var technicalRight: Bool
    public var isLimited: Bool
    public var permission: String
    public var permissions: MailboxLinkedPermissions
    public var productId: Int
    public var isPrimary: Bool
    public var lastAccessAt: String?
    public var ksuiteCustomerName: String?
    public var type: Int
}

public class MailboxLinkedPermissions: Codable {
    public var manageFilters: Bool
    public var manageSecurity: Bool
    public var manageAliases: Bool
    public var manageRedirections: Bool
    public var manageSignatures: Bool
    public var manageAutoReply: Bool
    public var changePassword: Bool
    public var configureMailFolders: Bool
    public var manageChat: Bool
    public var restoreEmails: Bool
    public var manageRules: Bool
    public var accessLogs: Bool
}
