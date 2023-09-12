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
import MailResources
import RealmSwift
import SwiftUI

public enum FolderRole: String, Codable, PersistableEnum {
    case archive = "ARCHIVE"
    case commercial = "COMMERCIAL"
    case draft = "DRAFT"
    case inbox = "INBOX"
    case sent = "SENT"
    case socialNetworks = "SOCIALNETWORKS"
    case spam = "SPAM"
    case trash = "TRASH"

    public var localizedName: String {
        switch self {
        case .archive:
            return MailResourcesStrings.Localizable.archiveFolder
        case .commercial:
            return MailResourcesStrings.Localizable.commercialFolder
        case .draft:
            return MailResourcesStrings.Localizable.draftFolder
        case .inbox:
            return MailResourcesStrings.Localizable.inboxFolder
        case .sent:
            return MailResourcesStrings.Localizable.sentFolder
        case .socialNetworks:
            return MailResourcesStrings.Localizable.socialNetworksFolder
        case .spam:
            return MailResourcesStrings.Localizable.spamFolder
        case .trash:
            return MailResourcesStrings.Localizable.trashFolder
        }
    }

    public var order: Int {
        switch self {
        case .archive:
            return 8
        case .commercial:
            return 2
        case .draft:
            return 5
        case .inbox:
            return 1
        case .sent:
            return 4
        case .socialNetworks:
            return 3
        case .spam:
            return 6
        case .trash:
            return 7
        }
    }

    public var icon: MailResourcesImages {
        switch self {
        case .archive:
            return MailResourcesAsset.archives
        case .commercial:
            return MailResourcesAsset.promotions
        case .draft:
            return MailResourcesAsset.draft
        case .inbox:
            return MailResourcesAsset.drawer
        case .sent:
            return MailResourcesAsset.send
        case .socialNetworks:
            return MailResourcesAsset.socialMedia
        case .spam:
            return MailResourcesAsset.spam
        case .trash:
            return MailResourcesAsset.bin
        }
    }

    public static let writtenByMeFolders: [FolderRole] = [.sent, .draft]
}

public enum ToolFolderType: String, PersistableEnum {
    case search
}

public class Folder: Object, Codable, Comparable, Identifiable {
    @Persisted(primaryKey: true) public var _id: String
    @Persisted public var path: String
    @Persisted public var name: String
    @Persisted public var role: FolderRole?
    @Persisted public var unreadCount = 0
    @Persisted public var remoteUnreadCount = 0
    @Persisted public var isFavorite: Bool
    @Persisted public var separator: String
    @Persisted public var children: MutableSet<Folder>
    @Persisted public var threads: MutableSet<Thread>
    @Persisted public var messages: MutableSet<Message>
    @Persisted(originProperty: "children") public var parents: LinkingObjects<Folder>
    @Persisted public var toolType: ToolFolderType?
    @Persisted public var cursor: String?
    @Persisted public var remainingOldMessagesToFetch = Constants.messageQuantityLimit
    @Persisted public var isHistoryComplete = false
    @Persisted public var isExpanded = true

    /// Date of last threads update
    @Persisted public var lastUpdate: Date?

    public var id: String {
        return _id
    }

    public var listChildren: AnyRealmCollection<Folder>? {
        children.isEmpty ? nil : AnyRealmCollection(children)
    }

    public var parent: Folder? {
        return parents.first
    }

    public var localizedName: String {
        return role?.localizedName ?? name
    }

    public var icon: Image {
        let asset = role?.icon ?? (isFavorite ? MailResourcesAsset.folderStar : MailResourcesAsset.folder)
        return asset.swiftUIImage
    }

    public var formattedUnreadCount: String {
        let realCount = (role == .draft ? threads.count : unreadCount)
        if realCount >= 100 {
            return "99+"
        }
        return realCount > 0 ? "\(realCount)" : ""
    }

    public var formattedPath: String {
        var names = [String]()
        var maybeFolder: Folder? = self
        while let folder = maybeFolder {
            names.append(folder.localizedName)
            maybeFolder = folder.parent
        }
        return names.reversed().joined(separator: " > ")
    }

    public var matomoName: String {
        guard let role else { return "customFolder" }

        var folderName = role.rawValue.lowercased()
        if role == .socialNetworks {
            folderName = "socialNetworks"
        }
        return "\(folderName)Folder"
    }

    public static func < (lhs: Folder, rhs: Folder) -> Bool {
        if let lhsRole = lhs.role, let rhsRole = rhs.role {
            return lhsRole.order < rhsRole.order
        } else if lhs.role != nil {
            return true
        } else if rhs.role != nil {
            return false
        } else if lhs.isFavorite == rhs.isFavorite {
            return lhs.path < rhs.path
        } else {
            return lhs.isFavorite
        }
    }

    public static func == (lhs: Folder, rhs: Folder) -> Bool {
        return lhs.id == rhs.id
    }

    public func computeUnreadCount() {
        unreadCount = threads.where { $0.unseenMessages > 0 }.count
    }

    public func completeHistoryInfo() {
        remainingOldMessagesToFetch = 0
        isHistoryComplete = true
    }

    public func resetHistoryInfo() {
        remainingOldMessagesToFetch = Constants.messageQuantityLimit
        isHistoryComplete = false
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

    public func verifyFilter(_ filter: String) -> Bool {
        return localizedName.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(filter)
    }

    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case path
        case name
        case role
        case isFavorite
        case separator
        case children
        case remoteUnreadCount = "unreadCount"
    }

    public convenience init(
        id: String,
        path: String,
        name: String,
        role: FolderRole? = nil,
        unreadCount: Int = 0,
        isFavorite: Bool,
        separator: String,
        children: [Folder],
        toolType: ToolFolderType? = nil
    ) {
        self.init()

        _id = id
        self.path = path
        self.name = name
        self.role = role
        self.unreadCount = unreadCount
        self.isFavorite = isFavorite
        self.separator = separator

        self.children = MutableSet()
        self.children.insert(objectsIn: children)

        self.toolType = toolType
    }
}
