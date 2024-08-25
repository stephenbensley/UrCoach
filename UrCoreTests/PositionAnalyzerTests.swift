//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import XCTest

class PositionAnalyzerTests: XCTestCase {
    func testPolicy() throws {
        for pos in GamePosition.randomPositions {
            let policy = solution.policy(for: pos)
            for roll in 1...4 {
                let moves = pos.moves(forRoll: roll)
                guard !moves.isEmpty else { continue }
                let best = solution.bestMove(from: pos, forRoll: roll)
                XCTAssert(moves[policy[roll - 1]] == best)
            }
         }
    }
}
