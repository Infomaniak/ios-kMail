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
import InfomaniakCore
import RealmSwift

public enum FolderRole: String, Codable, PersistableEnum {
    case archive = "ARCHIVE"
    case draft = "DRAFT"
    case inbox = "INBOX"
    case sent = "SENT"
    case spam = "SPAM"
    case trash = "TRASH"

    var localizedName: String {
        switch self {
        case .archive:
            return "Archives"
        case .draft:
            return "Drafts"
        case .inbox:
            return "Inbox"
        case .sent:
            return "Sent"
        case .spam:
            return "Spam"
        case .trash:
            return "Trash"
        }
    }

    public var order: Int {
        switch self {
        case .archive:
            return 6
        case .draft:
            return 2
        case .inbox:
            return 1
        case .sent:
            return 3
        case .spam:
            return 4
        case .trash:
            return 5
        }
    }
}

public class Folder: Object, Codable, Comparable, Identifiable {
    @Persisted(primaryKey: true) public var _id: String
    @Persisted public var path: String
    @Persisted public var name: String
    @Persisted public var role: FolderRole?
    @Persisted public var unreadCount: Int?
    @Persisted public var totalCount: Int?
    @Persisted public var isFake: Bool
    @Persisted public var isCollapsed: Bool
    @Persisted public var isFavorite: Bool
    @Persisted public var separator: String
    @Persisted public var children: MutableSet<Folder>
    @Persisted public var threads: MutableSet<Thread>
    @Persisted(originProperty: "children") public var parentLink: LinkingObjects<Folder>

    public var id: String {
        return _id
    }

    public var listChildren: AnyRealmCollection<Folder>? {
        children.isEmpty ? nil : AnyRealmCollection(children)
    }

    public var parent: Folder? {
        return parentLink.first
    }

    public var localizedName: String {
        return role?.localizedName ?? name
    }

    public static func < (lhs: Folder, rhs: Folder) -> Bool {
        if let lhsRole = lhs.role, let rhsRole = rhs.role {
            return lhsRole.order < rhsRole.order
        } else if lhs.role != nil {
            return true
        } else if rhs.role != nil {
            return false
        } else if lhs.isFavorite == rhs.isFavorite {
            return lhs.name < rhs.name
        } else {
            return lhs.isFavorite
        }
    }

    public static func == (lhs: Folder, rhs: Folder) -> Bool {
        return lhs.id == rhs.id
    }

    public func isParent(of folder: Folder) -> Bool {
        let myComponents = path.components(separatedBy: separator)
        let folderComponents = folder.path.components(separatedBy: separator)
        guard myComponents.count <= folderComponents.count else { return false }
        for i in 0 ..< myComponents.count where myComponents[i] != folderComponents[i] {
            return false
        }
        return true
    }

    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case path
        case name
        case role
        case unreadCount
        case totalCount
        case isFake
        case isCollapsed
        case isFavorite
        case separator
        case children
    }

    public convenience init(
        id: String,
        path: String,
        name: String,
        role: FolderRole? = nil,
        unreadCount: Int? = nil,
        totalCount: Int? = nil,
        isFake: Bool,
        isCollapsed: Bool,
        isFavorite: Bool,
        separator: String,
        children: [Folder]
    ) {
        self.init()

        _id = id
        self.path = path
        self.name = name
        self.role = role
        self.unreadCount = unreadCount
        self.totalCount = totalCount
        self.isFake = isFake
        self.isCollapsed = isCollapsed
        self.isFavorite = isFavorite
        self.separator = separator

        self.children = MutableSet()
        self.children.insert(objectsIn: children)
    }
}
