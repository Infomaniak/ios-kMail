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
import InfomaniakLogin
@testable import MailCore
import XCTest

/// Like in vidja games, you can start form noise (random stuff) to build a world.
/// So here I build a N dimensional array of [Folders] given random data
public struct FoldableFolderGenerator {
    let maxDepth: Int
    let maxElementsPerLevel: Int

    /// Init of UTFoldableFolderGenerator
    /// - Parameters:
    ///   - maxDepth: The depth of the tree structure to generate, must be positive or zero
    ///   - maxElementsPerLevel: The width of the tree structure to generate, must be positive or zero
    public init(maxDepth: Int, maxElementsPerLevel: Int) {
        assert(maxDepth >= 0, "maxDepth should be positive integer. Got:\(maxDepth)")
        assert(maxElementsPerLevel >= 0, "maxElementsPerLevel should be positive integer. Got:\(maxElementsPerLevel)")

        self.maxDepth = maxDepth
        self.maxElementsPerLevel = maxElementsPerLevel
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

    public func invokeFromNoise() -> [Folder] {
        // Building the depth of my array to be tested
        let randomDepth = depthMap

        // Start to populate it
        let result = randomDepth.map {
            folder(withChildren: buildBranch(depth: $0))
        }

        return result
    }

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

    private func folder(withChildren children: [Folder]) -> Folder {
        Folder(remoteId: randomID,
               path: randomPath,
               name: randomWord,
               isFavorite: randomFavorite,
               separator: "some",
               children: children)
    }

    var depthMap: [Int] {
        (0 ..< maxElementsPerLevel).map { _ in Int.random(in: 0 ... maxDepth) }
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
