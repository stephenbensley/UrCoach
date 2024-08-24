//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

// Stores the value of a Move
public struct MoveValue: Comparable {
    let move: Move
    let value: Float
    
    public static func == (lhs: MoveValue, rhs: MoveValue) -> Bool { lhs.value == rhs.value }
    public static func < (lhs: MoveValue, rhs: MoveValue) -> Bool { lhs.value < rhs.value }
}

// Protocol for analyzing a game position.
public protocol PositionAnalyzer {
    // Returns all moves sorted from best to worst.
    func analyze(position: GamePosition, roll: Int) throws -> [MoveValue]
    
    // Returs the best move.
    func bestMove(from position: GamePosition, forRoll roll: Int) throws -> Move?
}

// Extend PositionValues to implement PositionAnalyzer.
extension PositionValues: PositionAnalyzer {
    // Returns all moves sorted from best to worst.
    public func analyze(position: GamePosition, roll: Int) -> [MoveValue] {
        evaluateMoves(position: position, roll: roll).sorted(by: >)
    }
    
    public func bestMove(from position: GamePosition, forRoll roll: Int) -> Move? {
        analyze(position: position, roll: roll).first?.move
    }
    
    // Returns the policy for rolls 1...4. The policy is index of the best move in the moves array
    // or 0 if no move is available.
    func policy(for position: GamePosition) -> [Int] {
        (1...4).map { policyForRoll(position: position, roll: $0) }
    }
    
    // Assigns a value to each move.
    private func evaluateMoves(position: GamePosition, roll: Int) -> [MoveValue] {
        position.moves(forRoll: roll).map({ move in
            let (nextPosition, nextPlayer) = position.tryMove(move: move)
            let value = self[nextPosition]
            return MoveValue(move: move, value: (nextPlayer ? 1.0 - value : value))
        })
    }
    
    // Computes the policy for a roll.
    private func policyForRoll(position: GamePosition, roll: Int) -> Int {
        evaluateMoves(position: position, roll: roll).enumerated().max(by: {
            $0.1 < $1.1
        })?.0 ?? 0
    }
}
