/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import MailResources
import RealmSwift
import SwiftUI

public enum FolderRole: String, Codable, PersistableEnum, CaseIterable {
    case archive = "ARCHIVE"
    case commercial = "COMMERCIAL"
    case draft = "DRAFT"
    case scheduledDrafts = "SCHEDULED_DRAFTS"
    case inbox = "INBOX"
    case sent = "SENT"
    case socialNetworks = "SOCIALNETWORKS"
    case spam = "SPAM"
    case trash = "TRASH"
    case unknown

    public var localizedName: String {
        switch self {
        case .archive:
            return MailResourcesStrings.Localizable.archiveFolder
        case .commercial:
            return MailResourcesStrings.Localizable.commercialFolder
        case .draft:
            return MailResourcesStrings.Localizable.draftFolder
        case .scheduledDrafts:
            return MailResourcesStrings.Localizable.scheduledMessagesFolder
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
        case .unknown:
            return ""
        }
    }

    public var order: Int {
        switch self {
        case .archive:
            return 9
        case .commercial:
            return 2
        case .draft:
            return 6
        case .scheduledDrafts:
            return 5
        case .inbox:
            return 1
        case .sent:
            return 4
        case .socialNetworks:
            return 3
        case .spam:
            return 7
        case .trash:
            return 8
        case .unknown:
            return 0
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
        case .scheduledDrafts:
            return MailResourcesAsset.clockPaperplane
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
        case .unknown:
            return MailResourcesAsset.circleQuestionmark
        }
    }

    public static let writtenByMeFolders: [FolderRole] = [.sent, .draft, .scheduledDrafts]

    public init(from decoder: any Decoder) throws {
        let singleKeyContainer = try decoder.singleValueContainer()
        let value = try singleKeyContainer.decode(String.self)

        self = FolderRole(rawValue: value) ?? .unknown
    }
}

public enum ToolFolderType: String, PersistableEnum {
    case search
}

public class MessageUid: EmbeddedObject {
    @Persisted public var uid: String

    override public init() {
        super.init()
    }

    public convenience init(uid: String) {
        self.init()
        self.uid = uid
    }
}

public class Folder: Object, Codable, Comparable, Identifiable {
    @Persisted(primaryKey: true) public var remoteId: String
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
    /// List of old Messages UIDs of this Folder that we need to fetch.
    /// When first opening the Folder, we get the full list of UIDs, and we store it.
    /// Then, we'll be able to go through it as we want to fetch the old Messages.
    @Persisted public var oldMessagesUidsToFetch: RealmSwift.List<MessageUid>
    /// List of new Messages UIDs of this Folder that we need to fetch.
    @Persisted public var newMessagesUidsToFetch: RealmSwift.List<MessageUid>
    @Persisted public var isExpanded = true

    /// Date of last threads update
    @Persisted public var lastUpdate: Date?

    public var listChildren: AnyRealmCollection<Folder>? {
        children.isEmpty ? nil : AnyRealmCollection(children)
    }

    public var isHistoryComplete: Bool {
        return oldMessagesUidsToFetch.isEmpty
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

    public var shouldBeDisplayed: Bool {
        guard name != ".ik" && role != .unknown else { return false }
        guard !(role == .scheduledDrafts && threads.isEmpty) else { return false }
        return true
    }

    public var hasLimitedSwipeActions: Bool {
        return [.draft, .scheduledDrafts].contains(role)
    }

    public var formattedUnreadCount: String {
        let realCount = ((role == .draft || role == .scheduledDrafts) ? threads.count : unreadCount)
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

    public var permanentlyDeleteContent: Bool {
        return [FolderRole.draft, FolderRole.spam, FolderRole.trash, FolderRole.scheduledDrafts].contains(role)
    }

    public var shouldWarnBeforeDeletion: Bool {
        permanentlyDeleteContent && (role != .draft && role != .scheduledDrafts)
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

    public func computeUnreadCount() {
        unreadCount = threads.where { $0.unseenMessages > 0 }.count
    }

    public func resetHistoryInfo() {
        remainingOldMessagesToFetch = Constants.messageQuantityLimit
        oldMessagesUidsToFetch.removeAll()
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
        case remoteId = "id"
        case path
        case name
        case role
        case isFavorite
        case separator
        case children
        case remoteUnreadCount = "unreadCount"
    }

    public convenience init(
        remoteId: String,
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

        self.remoteId = remoteId
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

public extension Collection where Element: Folder {
    func sortedByFavoriteAndName() -> [Self.Element] {
        return sorted {
            $0.isFavorite == $1.isFavorite ? $0.name.localizedStandardCompare($1.name) == .orderedAscending : $0.isFavorite && !$1
                .isFavorite
        }
    }
}
