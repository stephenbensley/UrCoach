//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import XCTest

class CloudDBClientTests: XCTestCase {
    func testGetNode() async throws {
        let client = CloudDBClient()
        let position = GamePosition.randomPositions[0]
        let expected = solution.solutionNode(for: position)
        let actual = try await client.getNode(id: position.id)
        XCTAssert(SolutionNode.identical(expected, actual))
    }
    
    func testGetNodes() async throws {
        let client = CloudDBClient()
        let positions = GamePosition.randomPositions.prefix(7)
        let expectedIds = positions.map { $0.id }
        let actualIds = try await client.getNodes(ids: expectedIds).map({ $0.id })
        XCTAssert(expectedIds.sorted() == actualIds.sorted())
    }
}
