//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import XCTest
@testable import UrCore
@testable import UrPlay

let solution = PositionValues(fileURLWithPath: "urSolution.data")!

class DynamoNodeTests: XCTestCase {
    func testConvert() throws {
        for pos in GamePosition.randomPositions {
            let before = solution.solutionDbNode(for: pos)
            let after = DynamoNode(before).solutionDBNode!
            XCTAssert(before == after)
        }
    }
}
