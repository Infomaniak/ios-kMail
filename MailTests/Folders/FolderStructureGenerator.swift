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
import InfomaniakLogin
@testable import MailCore
@testable import RealmSwift
import XCTest

/// Like in vidja games, you can start form noise (random stuff) to build a world.
/// So here I build a N dimensional array of [Folders] given random data
public struct FolderStructureGenerator {
    public let maxDepth: Int
    public let maxElementsPerLevel: Int

    /// Folders structure generated at init. Added to `inMemoryRealm`
    public var folders = [Folder]()

    /// Folders with a random Role. Added to `inMemoryRealm`
    public var foldersWithRole = [Folder]()

    var inMemoryRealm: Realm {
        let identifier = "MockRealm"
        let configuration = Realm.Configuration(inMemoryIdentifier: identifier, objectTypes: [
            Folder.self,
            Thread.self,
            Message.self,
            Body.self,
            Attachment.self,
            Recipient.self,
            Draft.self,
            Signature.self,
            SearchHistory.self
        ])

        // It's a unit test
        // swiftlint:disable:next force_try
        let realm = try! Realm(configuration: configuration)
        return realm
    }

    /// Init of UTFoldableFolderGenerator
    /// - Parameters:
    ///   - maxDepth: The depth of the tree structure to generate, must be positive or zero
    ///   - maxElementsPerLevel: The width of the tree structure to generate, must be positive or zero
    public init(maxDepth: Int, maxElementsPerLevel: Int) {
        assert(maxDepth >= 0, "maxDepth should be positive integer. Got:\(maxDepth)")
        assert(maxElementsPerLevel >= 0, "maxElementsPerLevel should be positive integer. Got:\(maxElementsPerLevel)")

        self.maxDepth = maxDepth
        self.maxElementsPerLevel = maxElementsPerLevel

        // Building the depth of my array to be tested
        let randomDepth = (0 ..< maxElementsPerLevel).map { _ in Int.random(in: 0 ... maxDepth) }

        // Start to populate it
        folders = randomDepth.map {
            folder(withChildren: buildBranch(depth: $0))
        }

        // Produce folders with a role
        foldersWithRole = FolderRole.allCases.map { role in
            folder(withChildren: [], role: role)
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
    func buildBranch(depth: Int) -> [Folder] {
        guard depth > 0 else {
            return []
        }

        var buffer = [Folder]()
        for _ in 0 ..< elementsCountForDepth {
            let nextDepth = depth - 1
            if nextDepth > 0 {
                let subBranch = folder(withChildren: buildBranch(depth: nextDepth))
                buffer.append(subBranch)
            }
        }
        return buffer
    }

    private func folder(withChildren children: [Folder], role: FolderRole? = nil) -> Folder {
        let folder = Folder(remoteId: randomID,
                            path: randomPath,
                            name: randomWord,
                            role: role,
                            isFavorite: randomFavorite,
                            separator: "some",
                            children: children)
        // It's a unit test
        // swiftlint:disable:next force_try
        try! inMemoryRealm.write {
            inMemoryRealm.add(folder, update: .modified)
        }
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
}
