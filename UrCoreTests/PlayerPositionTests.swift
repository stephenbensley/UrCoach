//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import XCTest

class PlayerPositionTests: XCTestCase {
    func testTerminal() throws {
        XCTAssert(UrP("0 ---- -------- --").terminal)
        XCTAssertFalse(UrP("1 ---- -------- --").terminal)
        XCTAssertFalse(UrP("0 ---- --X----- --").terminal)
    }
    
    func testUnsafeCount() throws {
        XCTAssert(UrP("1 -XX- ----XX-- -X").safeCount == 2)
    }
    
    func testBitboardIntersects() throws {
        let other = UrP("1 -XXX ----XX-- -X")
        XCTAssertFalse(UrP("1 -XXX XXXX--XX -X").intersects(with: other))
        XCTAssert(UrP("1 X--- ----X--- X-").intersects(with: other))
    }
    
    func testOccupies() throws {
        let pos = UrP("1 -XXX ----XX-- -X")
        XCTAssert(pos.occupies(space: 2))
        XCTAssertFalse(pos.occupies(space: 4))
    }
    
    func testCapture() throws {
        var pos = UrP("1 -XXX ----XX-- -X")
        pos.capture(pieceAt: 9)
        XCTAssert(pos == UrP("2 -XXX ----X--- -X"))
    }
    
    func testMakeMove() throws {
        var pos = UrP("1 -XXX ----XX-- -X")
        pos.makeMove(Move(from: -1, to: 0))
        XCTAssert(pos == UrP("0 XXXX ----XX-- -X"))

        pos.makeMove(Move(from: 3, to: 6))
        XCTAssert(pos == UrP("0 XXX- --X-XX-- -X"))
 
        pos.makeMove(Move(from: 13, to: 14))
        XCTAssert(pos == UrP("0 XXX- --X-XX-- --"))
    }
    
    func testAll() throws {
        var seen = [UInt16: Set<Int>]()
        for pos in PlayerPosition.all {
            // Make sure we don't generate duplicates.
            if !seen.contains(where: { $0.key == pos.bitboard }) {
                seen[pos.bitboard] = .init()
            }
            XCTAssert(seen[pos.bitboard]!.insert(pos.waitCount).inserted)
            
            // Make sure we don't generate invalid positions.
            let pieceCount = pos.bitboard.nonzeroBitCount + pos.waitCount
            XCTAssert(pieceCount <= Ur.pieceCount)
        }
    }
}
