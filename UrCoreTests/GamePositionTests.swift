//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import XCTest

class GamePositionTests: XCTestCase {
    func testId() throws {
        let pos = UrG("3/4 X--X/-O-- X------- XX/--")
        let id = pos.id
        XCTAssert(id == 0b111001_011_0000000000010_000010_100)
        XCTAssert(GamePosition(id: id) == pos)
    }
    
    func testReversed() throws {
        let a = UrP("4 --X- XX------ --")
        let d = UrP("2 -XX- ---X---- X-")
        XCTAssert(UrG(a, d).reversed == UrG(d, a))
    }
    
    func testTerminal() throws {
        let terminalPos = UrP("0 ---- -------- --")
        let posA =        UrP("1 -XX- ----XX-- -X")
        let posB =        UrP("0 ---- -------- -X")
         
        XCTAssert(UrG(terminalPos, posA).terminal)
        XCTAssert(UrG(posA, terminalPos).terminal)
        XCTAssert(UrG(terminalPos, terminalPos).terminal)
        XCTAssertFalse(UrG(posA, posB).terminal)
    }
    
    func testMoves() throws {
        // Blocked by defender on rosette
        var moves = UrG("0/0 ----/---- --XO---- --/--").moves(forRoll: 1)
        XCTAssert(moves.count == 0)

        // Capture piece
        moves = UrG("0/0 ----/---- ---XO--- --/--").moves(forRoll: 1)
        XCTAssert(moves.count == 1)
        XCTAssert(moves[0] == Move(from: 7, to: 8))
        
        // Blocked by own piece and defender on rosette. Only move is to enter board.
        moves = UrG("1/0 ---X/---- -X-O---- --/--").moves(forRoll: 2)
        XCTAssert(moves.count == 1)
        XCTAssert(moves[0] == Move(from: -1, to: 1))
        
        // Only move is to exit board.
        moves = UrG("0/0 ----/---- ---O---- X-/--").moves(forRoll: 2)
        XCTAssert(moves.count == 1)
        XCTAssert(moves[0] == Move(from: 12, to: 14))
        
        // All seven pieces can be moved.
        moves = UrG("1/7 --X-/---- X-X-X-X- X-/--").moves(forRoll: 1)
        XCTAssert(moves.count == 7)
    }
    
    func testMakeMove() throws {
        var pos = UrG("1/4 -XXX/---- -O--XX-- -X/O-")

        // X enters a piece
        var next = pos.makeMove(Move(from: -1, to: 0))
        XCTAssert(next)
        XCTAssert(pos == UrG("0/4 XXXX/---- -O--XX-- -X/O-").reversed)

        // O exits a piece
        next = pos.makeMove(Move(from: 12, to: 14))
        XCTAssert(next)
        XCTAssert(pos == UrG("0/4 XXXX/---- -O--XX-- -X/--"))
        
        // X moves to the center rosette.
        next = pos.makeMove(Move(from: 3, to: 7))
        XCTAssertFalse(next)
        XCTAssert(pos == UrG("0/4 XXX-/---- -O-XXX-- -X/--"))

        // X captures a piece
        next = pos.makeMove(Move(from: 2, to: 5))
        XCTAssert(next)
        XCTAssert(pos == UrG("0/5 XX--/---- -X-XXX-- -X/--").reversed)
        
        // Make sure O can't capture a safe piece.
        next = pos.makeMove(Move(from: -1, to: 1))
        XCTAssert(next)
        XCTAssert(pos == UrG("0/4 XX--/-O-- -X-XXX-- -X/--"))
    }
}
