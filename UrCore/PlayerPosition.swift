//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

// Represents a move in the game. If from < 0, a waiting piece is being moved onto the board.
// If to == Ur.spaceCount, the piece is being exited from the board.
struct Move: Equatable {
    let from: Int
    let to: Int
}

// Represents one players position in the game.
struct PlayerPosition: Equatable {
    // Bitboard storing the location of the player's pieces.
    private(set) var bitboard: UInt16
    // Internally, the wait count is stored as an Int8 to save memory.
    private var waitCountInternal: Int8
    
    // Returns true if this is a legal position
    var isValid: Bool { (boardCount + waitCount) <= Ur.pieceCount }

    // Number of pieces on the board.
    var boardCount: Int { bitboard.nonzeroBitCount }
    // Number of pieces waiting to enter the board.
    var waitCount: Int { Int(waitCountInternal) }
    
    // True if this player has exited all his pieces from the board.
    var terminal: Bool { (bitboard == 0) && (waitCount == 0) }
    
    // Number of pieces that have either exited the board or reached one of the final two safe
    // spaces. safeCount is useful for defining metastates since it can never decrease.
    var safeCount: Int { Ur.pieceCount - (bitboard & 0xfff).nonzeroBitCount - waitCount }

    // At start of game, all pieces are waiting to enter.
    init(bitboard: UInt16 = 0, waitCount: Int = Ur.pieceCount) {
        self.bitboard = bitboard
        self.waitCountInternal = Int8(waitCount)
    }
    
    // Returns true if any of this player's pieces occupies the same space as one of the other
    // player's pieces.
    func intersects(with pos: PlayerPosition) -> Bool {
        return (bitboard & pos.bitboard & 0xff0) != 0
    }
    
    // Returns true if the player has a piece occupying the space.
    func occupies(space: Int) -> Bool { bitboard & (1 << space) != 0 }

    // Capture the designated piece.
    mutating func capture(pieceAt space: Int) {
        assert(Ur.isShared(space: space) && !Ur.isSanctuary(space: space))
        remove(from: space)
        waitCountInternal += 1
    }
    
    // Execute the designated move.
    mutating func makeMove(_ move: Move) {
        if move.from < 0 {
            waitCountInternal -= 1
        } else {
            remove(from: move.from)
        }
        
        if move.to < Ur.spaceCount {
            place(to: move.to)
        }
    }
    
    private mutating func remove(from: Int) { bitboard &= ~(1 << from) }
    private mutating func place(to: Int) { bitboard |= (1 << to) }

    // Generates all valid PlayerPositions.
    static var all: [PlayerPosition] {
        var result = [PlayerPosition]()
        // It's easier to walk through all possible bitboards and discard the invalid ones rather
        // than try to be clever with permutations etc.
        for bitboard: UInt16 in 0..<0x4000 {
            let boardCount = bitboard.nonzeroBitCount
            guard boardCount <= Ur.pieceCount else { continue }
            let maxWaitCount = Ur.pieceCount - boardCount
            for waitCount in 0...maxWaitCount {
                result.append(.init(bitboard: bitboard, waitCount: waitCount))
            }
        }
        return result
    }
}
