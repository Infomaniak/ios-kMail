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
import XCTest

/// Integration TestSuite for NestableFolder
final class ITNestableFolder: XCTestCase {
    var maxDepth = 0
    var maxElementsPerLevel = 0

    override class func setUp() {
        super.setUp()

        MockingHelper.clearRegisteredTypes()
        MockingHelper.registerConcreteTypes(configuration: .minimal)
    }

    // MARK: - TestSuite

    override class var defaultTestSuite: XCTestSuite {
        let testSuite = XCTestSuite(name: NSStringFromClass(self))

        // Wide not deep
        _ = (0 ... 29).map { _ in
            let randomDepth = Int.random(in: 0 ... 5)
            let randomWidth = Int.random(in: 0 ... 10)
            addNewTest(maxDepth: randomDepth, maxElementsPerLevel: randomWidth, testSuite: testSuite)
        }

        // Deep not wide
        _ = (50 ... 79).map { _ in
            let randomDepth = Int.random(in: 0 ... 10)
            let randomWidth = Int.random(in: 0 ... 2)
            addNewTest(maxDepth: randomDepth, maxElementsPerLevel: randomWidth, testSuite: testSuite)
        }

        return testSuite
    }

    class func addNewTest(maxDepth: Int, maxElementsPerLevel: Int, testSuite: XCTestSuite) {
        for invocation in testInvocations {
            let newTestCase = ITNestableFolder(invocation: invocation)
            newTestCase.maxDepth = maxDepth
            newTestCase.maxElementsPerLevel = maxElementsPerLevel

            testSuite.addTest(newTestCase)
        }
    }

    // MARK: - Test

    func testFlatFolderStructureCorrectness() {
        // GIVEN
        let arrayShapeTester = ArrayShapeCompare()
        let folderStructure = FolderStructureGenerator(maxDepth: maxDepth, maxElementsPerLevel: maxElementsPerLevel).frozenFolders

        // WHEN
        let nestedFolders = NestableFolder.createFoldersHierarchy(from: folderStructure)

        // THEN
        do {
            try arrayShapeTester.compare(lhs: folderStructure, rhs: nestedFolders)
        } catch {
            XCTFail(
                "Unexpected :\(error) with maxDepth=\(maxDepth) maxElementsPerLevel=\(maxElementsPerLevel) nestedFolders:\(nestedFolders) folderStructure:\(folderStructure)"
            )
        }
    }
}
