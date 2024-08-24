//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import XCTest

class DynamoNodeTests: XCTestCase {
    func testConvert() throws {
        for pos in GamePosition.randomPositions {
            let before = solution.solutionNode(for: pos)
            let after = DynamoNode(before).solutionDBNode!
            XCTAssert(before.id == after.id)
            XCTAssert(before.value == after.value)
            XCTAssert(before.policy == after.policy)
        }
    }
}
