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

import Foundation
import MailResources

public struct AIShortcutAction: Identifiable {
    public let id: Int
    public let label: String
    public let icon: MailResourcesImages
    public let apiName: String
}

extension AIShortcutAction: Equatable {
    public static func == (lhs: AIShortcutAction, rhs: AIShortcutAction) -> Bool {
        return lhs.id == rhs.id
    }
}

public extension AIShortcutAction {
    static let edit = AIShortcutAction(
        id: 1,
        label: MailResourcesStrings.Localizable.aiMenuEditRequest,
        icon: MailResourcesAsset.pencil,
        apiName: "edit"
    )
    static let regenerate = AIShortcutAction(
        id: 2,
        label: MailResourcesStrings.Localizable.aiMenuRegenerate,
        icon: MailResourcesAsset.fileRegenerate,
        apiName: "redraw"
    )
    static let shorten = AIShortcutAction(
        id: 3,
        label: MailResourcesStrings.Localizable.aiMenuShorten,
        icon: MailResourcesAsset.shortenParagraph,
        apiName: "shorten"
    )
    static let expand = AIShortcutAction(
        id: 4,
        label: MailResourcesStrings.Localizable.aiMenuExpand,
        icon: MailResourcesAsset.expandParagraph,
        apiName: "develop"
    )
    static let seriousWriting = AIShortcutAction(
        id: 5,
        label: MailResourcesStrings.Localizable.aiMenuSeriousWriting,
        icon: MailResourcesAsset.briefcase,
        apiName: "tune-professional"
    )
    static let friendlyWriting = AIShortcutAction(
        id: 6,
        label: MailResourcesStrings.Localizable.aiMenuFriendlyWriting,
        icon: MailResourcesAsset.smiley,
        apiName: "tune-friendly"
    )
}
