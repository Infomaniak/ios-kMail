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
import InfomaniakCore

public struct NestableFolder: Identifiable {
    public var id: Int {
        // The id of a folder depends on its `remoteId` and the id of its children
        return children.collectionId(baseId: frozenContent.remoteId.hashValue)
    }

    /// The underlying _frozen_ Folder
    public let frozenContent: Folder

    /// `NestableFolder` childs
    public let children: [NestableFolder]

    public init(content: Folder, children: [NestableFolder]) {
        frozenContent = content.freezeIfNeeded()
        self.children = children
    }

    public static func createFoldersHierarchy(from folders: [Folder]) -> [Self] {
        var parentFolders = [NestableFolder]()

        for folder in folders {
            let sortedChildren = folder.children.sortedByFavoriteAndName()
            parentFolders.append(NestableFolder(
                content: folder,
                children: createFoldersHierarchy(from: sortedChildren)
            ))
        }

        return parentFolders
    }
}
