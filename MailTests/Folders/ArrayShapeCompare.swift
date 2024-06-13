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

/// Something to compare the "shape" of abstract n dimensional arrays
public struct ArrayShapeCompare {
    enum ComparisonError: Error {
        /// The count of two arrays are not matching
        case mismatchArrayCount(lhs: [Any], rhs: [Any])
        /// A mismatch between two objects is found (one is a collection the other is not)
        case mismatchType(lhs: Any?, rhs: Any?)
    }

    public func compare(lhs: [Any], rhs: [Any]) throws {
        guard lhs.count == rhs.count else {
            throw ComparisonError.mismatchArrayCount(lhs: lhs, rhs: rhs)
        }

        for index in lhs.indices {
            if let lhsArray = lhs[index] as? [Any],
               let rhsArray = rhs[index] as? [Any] {
                try compare(lhs: lhsArray, rhs: rhsArray)
            }

            // excluding one is an array but the other is not one
            let lhsArray = lhs[index] as? [Any]
            let rhsArray = rhs[index] as? [Any]
            guard (lhsArray == nil && rhsArray == nil) || (lhsArray != nil && rhsArray != nil) else {
                throw ComparisonError.mismatchType(lhs: lhs, rhs: rhs)
            }

            // two types non nil, same 'shape'
        }
    }
}

/// Testing that the tool `ArrayShapeCompare` is correct
final class UTArrayShapeCompare: XCTestCase {
    // MARK: - Test success

    func testArrayShapeCompare_success_empty() {
        // GIVEN
        let lhs = [Int]()
        let rhs: [String] = lhs.map { "\($0)" }
        let arrayShapeTester = ArrayShapeCompare()

        // WHEN
        do {
            try arrayShapeTester.compare(lhs: lhs, rhs: rhs)
        } catch {
            XCTFail("Unexpected :\(error)")
        }
    }

    func testArrayShapeCompare_success_flat() {
        // GIVEN
        let lhs = [1, 2, 3, 4, 5]
        let rhs = lhs.map { "\($0)" }

        let arrayShapeTester = ArrayShapeCompare()

        // WHEN
        do {
            try arrayShapeTester.compare(lhs: lhs, rhs: rhs)
        } catch {
            XCTFail("Unexpected :\(error)")
        }
    }

    func testArrayShapeCompare_success_nested() {
        // GIVEN
        let lhs = [[1], 2, 3, 4, 5, [[[6, 7, 8]]]] as [Any]
        let rhs = [["1"], "2", "3", "4", "5", [[["6", "7", "8"]]]] as [Any]

        let arrayShapeTester = ArrayShapeCompare()

        // WHEN
        do {
            try arrayShapeTester.compare(lhs: lhs, rhs: rhs)
        } catch {
            XCTFail("Unexpected :\(error)")
        }
    }

    func testArrayShapeCompare_success_nested_dictionary() {
        // GIVEN
        let lhs = [[1], 2, 3, 4, 5, [[[6, 7, 8]]]] as [Any]
        let rhs = [["1"], "2", "3", "4", "5", [[["6", "7", ["8": "valid shape"]]]]] as [Any]

        let arrayShapeTester = ArrayShapeCompare()

        // WHEN
        do {
            try arrayShapeTester.compare(lhs: lhs, rhs: rhs)
        } catch {
            XCTFail("Unexpected :\(error)")
        }
    }

    // MARK: - Test failure

    func testArrayShapeCompare_failureCount_empty() {
        // GIVEN
        let lhs = [Int]()
        let rhs = ["shape_mismatch"]
        let arrayShapeTester = ArrayShapeCompare()

        // WHEN
        do {
            try arrayShapeTester.compare(lhs: lhs, rhs: rhs)
            XCTFail("Expected to throw")
        } catch {
            guard let matchError = error as? ArrayShapeCompare.ComparisonError else {
                XCTFail("Unexpected :\(error)")
                return
            }

            switch matchError {
            case .mismatchType(let lhs, let rhs):
                XCTFail("Unexpected object mismatch - lhs:\(lhs) rhs:\(rhs)")
            case .mismatchArrayCount: break
                // array count mismatch expected
            }
        }
    }

    func testArrayShapeCompare_failureCount_flat() {
        // GIVEN
        let lhs = [1, 2, 3, 4, 5]
        let rhs = ["1", "2", "3", "4", "5", "6"]

        let arrayShapeTester = ArrayShapeCompare()

        // WHEN
        do {
            try arrayShapeTester.compare(lhs: lhs, rhs: rhs)
            XCTFail("Expected to throw")
        } catch {
            guard let matchError = error as? ArrayShapeCompare.ComparisonError else {
                XCTFail("Unexpected :\(error)")
                return
            }

            switch matchError {
            case .mismatchType(let lhs, let rhs):
                XCTFail("Unexpected object mismatch - lhs:\(lhs) rhs:\(rhs)")
            case .mismatchArrayCount: break
                // array count mismatch expected
            }
        }
    }

    func testArrayShapeCompare_failureCount_nested() {
        // GIVEN
        let lhs = [[1], 2, 3, 4, 5, [[[6, 7, 8]]]] as [Any]
        let rhs = [["1"], "2", "3", "4", "5", [[["6", "7", "mismatch", "8"]]]] as [Any]

        let arrayShapeTester = ArrayShapeCompare()

        // WHEN
        do {
            try arrayShapeTester.compare(lhs: lhs, rhs: rhs)
            XCTFail("Expected to throw")
        } catch {
            guard let matchError = error as? ArrayShapeCompare.ComparisonError else {
                XCTFail("Unexpected :\(error)")
                return
            }

            switch matchError {
            case .mismatchType(let lhs, let rhs):
                XCTFail("Unexpected object mismatch - lhs:\(lhs) rhs:\(rhs)")
            case .mismatchArrayCount: break
                // array count mismatch expected
            }
        }
    }

    func testArrayShapeCompare_failureType_flat() {
        // GIVEN
        let lhs = [1, 2, 3, 4, 5]
        let rhs = ["1", "2", "3", "4", ["5"]] as [Any]

        let arrayShapeTester = ArrayShapeCompare()

        // WHEN
        do {
            try arrayShapeTester.compare(lhs: lhs, rhs: rhs)
            XCTFail("Expected to throw")
        } catch {
            guard let matchError = error as? ArrayShapeCompare.ComparisonError else {
                XCTFail("Unexpected :\(error)")
                return
            }

            switch matchError {
            case .mismatchType: break
            // object mismatch expected
            case .mismatchArrayCount(let lhs, let rhs):
                XCTFail("Unexpected array count - lhs:\(lhs.count) rhs:\(rhs.count)")
            }
        }
    }

    func testArrayShapeCompare_failureType_nested() {
        // GIVEN
        let lhs = [[1], 2, 3, 4, 5, [[[6, 7, 8]]]] as [Any]
        let rhs = [["1"], "2", "3", "4", "5", [[["6", "7", ["8"]]]]] as [Any]

        let arrayShapeTester = ArrayShapeCompare()

        // WHEN
        do {
            try arrayShapeTester.compare(lhs: lhs, rhs: rhs)
            XCTFail("Expected to throw")
        } catch {
            guard let matchError = error as? ArrayShapeCompare.ComparisonError else {
                XCTFail("Unexpected :\(error)")
                return
            }

            switch matchError {
            case .mismatchType: break
            // object mismatch expected
            case .mismatchArrayCount(let lhs, let rhs):
                XCTFail("Unexpected array count - lhs:\(lhs.count) rhs:\(rhs.count)")
            }
        }
    }

    func testArrayShapeCompare_failureType_dictionary() {
        // GIVEN
        let lhs = [[1], 2, 3, 4, 5, [[[6, 7, 8]]]] as [Any]
        let rhs = [["1"], "2", "3", "4", "5", [[["6", "7", [["8", "woops"]]]]]] as [Any]

        let arrayShapeTester = ArrayShapeCompare()

        // WHEN
        do {
            try arrayShapeTester.compare(lhs: lhs, rhs: rhs)
            XCTFail("Expected to throw")
        } catch {
            guard let matchError = error as? ArrayShapeCompare.ComparisonError else {
                XCTFail("Unexpected :\(error)")
                return
            }

            switch matchError {
            case .mismatchType: break
            // object mismatch expected
            case .mismatchArrayCount(let lhs, let rhs):
                XCTFail("Unexpected array count - lhs:\(lhs.count) rhs:\(rhs.count)")
            }
        }
    }
}
