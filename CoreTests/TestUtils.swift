//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

// Load this once for any tests that need it.
let solution = PositionValues(fileURLWithPath: "urSolution.data")!

// Generate random test cases.
extension GamePosition {
    static func randomPosition() -> GamePosition {
        var pos: GamePosition
        repeat {
            // About 6.5% of ids are valid, but since this is test-only, it's easier to just
            // keep guessing until we find one, rather than try to be clever.
            pos = GamePosition(id: Int32.random(in: 0...Int32.max))
        } while !pos.isValid
        return pos
    }
    
    static let randomPositions = (0..<100).map{ _ in randomPosition() }
}

// Assorted functions to make test cases easier to define.

// Extract a bitboard from a string representation.
func extractBitboard(
    from: [Character],
    atIndices indices: [Int],
    forToken token: Character
) -> UInt16 {
    var bitmask: UInt16 = 0
    for bit in 0..<indices.count {
        if from[indices[bit]] == token {
            bitmask |= 1 << bit
        }
    }
    return bitmask
}

// PlayerPosition described as "3 ---- X--X---- -X"
func UrP(_ asString: String) -> PlayerPosition {
    let pieceIndices = [ 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 16, 17]
    
    let chars = Array(asString)
    assert(chars.count == 18)
    
    let bitboard = extractBitboard(from: chars, atIndices: pieceIndices, forToken: "X")
    let waitCount = Int(String(chars[0]))!
    return .init(bitboard: bitboard, waitCount: waitCount)
}

// GamePosition described as "3/4 X---/--O- X--OO--- -X/-O"
func UrG(_ asString: String) -> GamePosition {
    let attackerIndices = [ 4,  5,  6,  7, 14, 15, 16, 17, 18, 19, 20, 21, 23, 24]
    let defenderIndices = [ 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21, 26, 27]
    
    let chars = Array(asString)
    assert(chars.count == 28)
    
    let aBitboard = extractBitboard(from: chars, atIndices: attackerIndices, forToken: "X")
    let aWaitCount = Int(String(chars[0]))!

    let dBitboard = extractBitboard(from: chars, atIndices: defenderIndices, forToken: "O")
    let dWaitCount = Int(String(chars[2]))!
    
    return .init(
        attacker: .init(bitboard: aBitboard, waitCount: aWaitCount),
        defender: .init(bitboard: dBitboard, waitCount: dWaitCount)
    )
}

// Saves a lot of typing :)
func UrG(_ attacker: PlayerPosition, _ defender: PlayerPosition) -> GamePosition {
    .init(attacker: attacker, defender: defender)
}

extension SolutionNode {
    static func identical(_ lhs: SolutionNode, _ rhs: SolutionNode) -> Bool {
        (lhs.id == rhs.id) && (lhs.value == rhs.value) && (lhs.policy == rhs.policy)
    }
}
