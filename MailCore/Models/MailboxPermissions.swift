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

import RealmSwift

public class MailboxPermissions: Object, Codable {
    @Persisted public var canManageFilters: Bool
    @Persisted public var canManageSecurity: Bool
    @Persisted public var canManageAliases: Bool
    @Persisted public var canManageRedirections: Bool
    @Persisted public var canManageSignatures: Bool
    @Persisted public var canManageAutoReply: Bool
    @Persisted public var canManageChat: Bool
    @Persisted public var canChangePassword: Bool
    @Persisted public var canConfigureMailFolders: Bool
    @Persisted public var canRestoreEmails: Bool
    @Persisted public var canManageRules: Bool
    @Persisted public var canAccessLogs: Bool
    @Persisted public var hasTechnicalRights: Bool
    @Persisted public var isLimited: Bool
    @Persisted public var isFree: Bool
    @Persisted public var dailyLimit: Int
}
