//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import XCTest

class PositionValuesBuilderTests: XCTestCase {
    func test() throws {
        let builder = PositionValuesBuilder()
        
        let pos = UrG("0/4 XXXX/---- -O--XX-- -X/O-")
        XCTAssert(builder[pos] == 0.5)
        builder[pos] = 0.7
        XCTAssert(builder[pos] == 0.5)
        builder.toggle()
        XCTAssert(builder[pos] == 0.7)
    }
}
