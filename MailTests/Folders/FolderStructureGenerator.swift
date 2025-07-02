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

// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all


import Foundation
@testable import InfomaniakCore
@testable import InfomaniakCoreDB
import InfomaniakLogin
@testable import MailCore
@testable import RealmSwift
import XCTest

/// Like in vidja games, you can start form noise (random stuff) to build a world.
/// So here I build a N dimensional array of [Folders] given random data
public final class FolderStructureGenerator {
    public let transactionable: TransactionExecutor
    public let maxDepth: Int
    public let maxElementsPerLevel: Int

    public let mandatoryFolderRoles: [FolderRole] = [.inbox, .sent, .draft, .trash]

    /// Folders structure generated at init. Added to `inMemoryRealm`
    public var frozenFolders: [Folder] {
        _frozenFolders
    }

    var _frozenFolders = [Folder]()

    /// Folders with a random Role. Added to `inMemoryRealm`
    public var frozenFoldersWithRole: [Folder]! {
        _frozenFoldersWithRole
    }

    var _frozenFoldersWithRole = [Folder]()

    /// Init of UTFoldableFolderGenerator
    /// - Parameters:
    ///   - maxDepth: The depth of the tree structure to generate, must be positive or zero
    ///   - maxElementsPerLevel: The width of the tree structure to generate, must be positive or zero
    public init(maxDepth: Int, maxElementsPerLevel: Int) {
        assert(maxDepth >= 0, "maxDepth should be positive integer. Got:\(maxDepth)")
        assert(maxElementsPerLevel >= 0, "maxElementsPerLevel should be positive integer. Got:\(maxElementsPerLevel)")
        
        self.maxDepth = maxDepth
        self.maxElementsPerLevel = maxElementsPerLevel
        
        let realmAccessor = InMemoryRealmAccessor()
        
        self.transactionable = TransactionExecutor(realmAccessible: realmAccessor)
        
        // Building the depth of my array to be tested
        let randomDepth = (0 ..< maxElementsPerLevel).map { _ in Int.random(in: 0 ... maxDepth) }
        
        // Start to populate it
        _frozenFolders = randomDepth.map { depth in
            var folder: Folder!
            try! transactionable.writeTransaction { writableRealm in
                let childrenBranch = try! buildBranch(depth: depth, writableRealm: writableRealm)
                folder = self.folder(withChildren: childrenBranch, writableRealm: writableRealm)
            }
            return folder.freezeIfNeeded()
        }
        
        // Produce folders with a role
        _frozenFoldersWithRole = FolderRole.allCases.map { role in
            var folder: Folder!
            try! transactionable.writeTransaction { writableRealm in
                folder = self.folder(withChildren: [], role: role, writableRealm: writableRealm)
            }
            return folder.freeze()
        }
    }

    static let wordDictionary = [
        "Lorem",
        "ipsum",
        "dolor",
        "sit",
        "amet",
        "consectetur",
        "adipiscing",
        "elit",
        "sed",
        "do",
        "eiusmod",
        "tempor",
        "incididunt",
        "ut",
        "labore",
        "et",
        "dolore",
        "magna",
        "aliqua"
    ]

    static let pathDictionary = [
        "/bin",
        "/boot",
        "/boot/EFI",
        "/dev",
        "/dev/null",
        "/etc",
        "/mnt",
        "/mnt/cdrom",
        "/opt",
        "/opt/local/bin"
    ]

    /// Recursively builds a branch of Folders
    func buildBranch(depth: Int, writableRealm: Realm) throws -> [Folder] {
        guard depth > 0 else {
            return []
        }

        var buffer = [Folder]()
        for _ in 0 ..< elementsCountForDepth {
            let nextDepth = depth - 1
            if nextDepth > 0 {
                let childrenBranch = try buildBranch(depth: nextDepth, writableRealm: writableRealm)
                let subBranch = folder(withChildren: childrenBranch, writableRealm: writableRealm)
                buffer.append(subBranch)
            }
        }
        
        return buffer
    }

    private func folder(withChildren children: [Folder],
                               role: FolderRole? = nil,
                               writableRealm: Realm) -> Folder {
        let folder = Folder(remoteId: randomID,
                            path: randomPath,
                            name: randomWord,
                            role: role,
                            isFavorite: randomFavorite,
                            separator: "some",
                            children: children)
        writableRealm.add(folder, update: .modified)
        return folder
    }

    var elementsCountForDepth: Int {
        Int.random(in: 0 ... maxElementsPerLevel)
    }

    var randomWord: String {
        Self.wordDictionary.randomElement()!
    }

    var randomPath: String {
        Self.pathDictionary.randomElement()!
    }

    var randomID: String {
        UUID().uuidString
    }

    var randomFavorite: Bool {
        Bool.random()
    }

    deinit {
        try? transactionable.writeTransaction { writableRealm in
            writableRealm.deleteAll()
        }
    }

}

/// Something to access the in memory realm
final class InMemoryRealmAccessor: RealmAccessible {
    let inMemoryRealm: Realm  = {
        let identifier = "MockRealm-\(UUID().uuidString)"
        let configuration = Realm.Configuration(inMemoryIdentifier: identifier, objectTypes: [
            Folder.self,
            Thread.self,
            Message.self,
            Body.self,
            SubBody.self,
            Attachment.self,
            Recipient.self,
            Draft.self,
            Signature.self,
            SearchHistory.self,
            CalendarEventResponse.self,
            CalendarEvent.self,
            Attendee.self,
            Bimi.self,
            SwissTransferAttachment.self,
            File.self,
            MessageUid.self,
            MessageHeaders.self,
            BookableResource.self,
            MessageReaction.self,
            ReactionAuthor.self
        ])

        // It's a unit test
        // swiftlint:disable:next force_try
        let realm = try! Realm(configuration: configuration)
        return realm
    }()
    
    // MARK: RealmAccessible

    func getRealm() -> RealmSwift.Realm {
        inMemoryRealm
    }
}

// swiftlint:enable all
// swiftformat:enable all
