//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import XCTest

class GameModelTests: XCTestCase {
    func testRollDice() throws {
        let iterations = 100_000
        var counts = [Int](repeating: 0, count: 5)
        for _ in 0..<iterations {
            counts[GameModel.rollDice().reduce(0, +)] += 1
        }
        
        XCTAssertEqual(Double(counts[0]) / Double(iterations), 0.0625, accuracy: 0.01)
        XCTAssertEqual(Double(counts[1]) / Double(iterations), 0.2500, accuracy: 0.01)
        XCTAssertEqual(Double(counts[2]) / Double(iterations), 0.3750, accuracy: 0.01)
        XCTAssertEqual(Double(counts[3]) / Double(iterations), 0.2500, accuracy: 0.01)
        XCTAssertEqual(Double(counts[4]) / Double(iterations), 0.0625, accuracy: 0.01)
   }
}
