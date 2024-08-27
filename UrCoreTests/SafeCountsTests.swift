//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import XCTest

class SafeCountsTests: XCTestCase {
    func testAll() throws {
        let counts = SafeCounts.all
        XCTAssert(counts.count == (8 + 8 * 7 / 2))
        
        var seen = Set<SafeCounts>()
        for count in counts {
            XCTAssert(count.hi >= count.lo)
            XCTAssert(count.hi <= Ur.pieceCount)
            XCTAssert(count.lo <= Ur.pieceCount)
            XCTAssert(seen.insert(count).inserted)
        }
    }
}
