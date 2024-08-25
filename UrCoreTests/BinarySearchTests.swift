//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import XCTest

class BinarySearchTests: XCTestCase {
    func testBSearch() throws {
        let array = (0..<100).map({ _ in Int.random(in: (0..<1_000_000)) }).sorted()
        
        for i in array.indices {
            let match = array.bsearch(for: array[i])
            XCTAssertNotNil(match)
            XCTAssert(match! == i)
        }
        
        XCTAssertNil(array.bsearch(for: -1))
        XCTAssertNil(array.bsearch(for: 1_000_001))
    }
}
