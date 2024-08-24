//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

// Extend PlayerPosition to make it easier to compute GamePosition id's.
extension PlayerPosition {
    // Bitboard representing only the spaces shared with the other player.
    var bitboardShared: UInt8 { UInt8( (bitboard >> 4) & 0xff) }
    
    // Bitboard representing the spaces unique to this player.
    var bitboardUnique: UInt8 { UInt8(((bitboard >> 8) & 0x30) | (bitboard & 0xf)) }
}

// Represents a position in the game without regard to which player has the next move. Ur is
// symmetric with regard to player color, so we can analyze a position without knowing which player
// moves next.
public struct GamePosition: Equatable, Identifiable {
    // Player with the next move.
    private(set) var attacker: PlayerPosition
    // Player without the next move.
    private(set) var defender: PlayerPosition
    
    // Id uniquely identifying this position.
    public var id: Int32 {
        let aUnique = Int32(attacker.bitboardUnique)
        let aShared = attacker.bitboardShared
        let aWait   = Int32(attacker.waitCount)
        
        let dUnique = Int32(defender.bitboardUnique)
        let dShared = defender.bitboardShared
        let dWait   = Int32(defender.waitCount)
        
        // The binary bitboards are merged into a shared ternary bitboard to save space.
        let shared  = Int32(Self.sharedIds[Int(aShared) << 8 | Int(dShared)])
        
        //  0 -  2: dWait
        //  3 -  8: dUnique
        //  9 - 21: shared
        // 22 - 24: aWait
        // 25 - 30: aUnique
        return dWait | (dUnique << 3) | (shared << 9) | (aWait << 22) | (aUnique << 25)
    }
    
    // Returns true if this is a legal position
    var isValid: Bool {
        attacker.isValid && defender.isValid && !attacker.intersects(with: defender)
    }

    // Returns the current position reversed.
    var reversed: GamePosition { .init(attacker: defender, defender: attacker) }
    
    // True if the game is over.
    var terminal: Bool { attacker.terminal || defender.terminal }
    
    public init(attacker: PlayerPosition = .init(), defender: PlayerPosition = .init()) {
        self.attacker = attacker
        self.defender = defender
    }
    
    init(id: Int32) {
        let dWait   =  id        & 0x0007
        let dUnique = (id >>  3) & 0x003f
        var shared  = (id >>  9) & 0x1fff
        let aWait   = (id >> 22) & 0x0007
        let aUnique = (id >> 25) & 0x003f
        
        var aShared: Int32 = 0
        var dShared: Int32 = 0
        var mask: Int32 = 1
        while shared != 0 {
            let token = shared % 3
            if token == 2 {
                aShared |= mask
            } else if token == 1 {
                dShared |= mask
            }
            shared /= 3
            mask <<= 1
        }
 
        let aBitboard = ((aUnique & 0x30) << 8) | (aShared << 4) | (aUnique & 0xf)
        let dBitboard = ((dUnique & 0x30) << 8) | (dShared << 4) | (dUnique & 0xf)
        
        self.attacker = .init(bitboard: UInt16(aBitboard), waitCount: Int(aWait))
        self.defender = .init(bitboard: UInt16(dBitboard), waitCount: Int(dWait))
   }
    
    // Returns all legal moves from the position.
    func moves(forRoll roll: Int) -> [Move] {
        // A roll of 0 never has any moves.
        guard roll > 0 else { return .init() }
        
        // Pieces must exit the board by exact count, so compute the highest space number that
        // could possibly move.
        let maxFrom = Ur.spaceCount - roll
        
        // Collect the moves for pieces already on the board.
        var moves: [Move] = (0...maxFrom).compactMap { from in
            // Can't move from a space if you don't have a piece there.
            guard attacker.occupies(space: from) else { return nil }
            let to = from + roll
            // You're always blocked by your own pieces.
            guard !attacker.occupies(space: to) else { return nil }
            // You're also blocked by an opponent on the middle rosette.
            guard !Ur.isSanctuary(space: to) || !defender.occupies(space: to) else {
                return nil
            }
            return .init(from: from, to: to)
        }
        
        // Add a move to enter a waiting piece if possible.
        if attacker.waitCount > 0 && !attacker.occupies(space: roll - 1) {
            moves.append(.init(from: -1, to: roll - 1))
        }
        
        return moves
    }
    
    // Apply the move; returns true if play passes to the next player
    mutating func makeMove(_ move: Move) -> Bool {
        attacker.makeMove(move)
        if Ur.isShared(space: move.to) && defender.occupies(space: move.to) {
            defender.capture(pieceAt: move.to)
        }
        
        // If we landed on a rosette, it's still our move.
        if Ur.isRosette(space: move.to) {
            return false
        } else {
            swap(&attacker, &defender)
            return true
        }
    }
    
    // Apply the move and return the resulting GamePosition
    func tryMove(move: Move) -> (GamePosition, Bool) {
        var nextPosition = self
        let nextPlayer = nextPosition.makeMove(move)
        return (nextPosition, nextPlayer)
    }
    
    // Invoke the closure for every possible GamePosition
    public static func forEach(_ body: (GamePosition) throws -> Void) rethrows {
        let ppa = PlayerPosition.all
        for attacker in ppa {
            for defender in ppa where !defender.intersects(with: attacker) {
                try body(.init(attacker: attacker, defender: defender))
            }
        }
    }
    
    // Ids representing the shared spaces on the board. We use a ternary representation in order
    // to squeeze this into 13 bits. 13^2 > 8^3
    static let sharedIds = (0...0xffff).map {
        // Extract the shared bitboards for each side.
        let lhs = UInt8($0 >> 8)
        let rhs = UInt8($0 & 0xff)
        
        var shared: Int16 = 0
        
        // During the game, these should never collide, but we store a dummy value, so we can use
        // an Array instead of a Dictionary for lookups.
        guard lhs & rhs == 0 else { return shared }
        
        // Start with the high order bit -- although it doesn't really matter.
        var mask: UInt8 = 0x80
        repeat {
            shared *= 3
            if lhs & mask != 0 {
                shared += 2
            } else if rhs & mask != 0 {
                shared += 1
            }
            mask >>= 1
        } while mask != 0
        
        return shared
    }
}
