//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

// Protocol for a strategy to play the game of Ur
protocol Strategy {
    func getMove(position: GamePosition, roll: Int) async throws -> Move?
}

// Strategy implemented by an analyzer.
final class AnalysisStrategy: Strategy {
    private var analyzer: PositionAnalyzer

    init(analyzer: PositionAnalyzer) {
        self.analyzer = analyzer
    }
    
    func getMove(position: GamePosition, roll: Int) async throws -> Move? {
        try await analyzer.bestMove(from: position, forRoll: roll)
    }
}

// Implements a simple heuristic-based strategy
final class HeuristicStrategy: Strategy {
    // Move types sorted from least to most desirable.
    private enum MoveType: Int {
        case simple
        case enterBoard
        case exitBoard
        case occupyRosette
        case capturePiece
    }
    
    init() { }
    
    func getMove(position: GamePosition, roll: Int) -> Move? {
        position.moves(
            forRoll: roll
        ).sorted(by: {
            Self.areInDecreasingOrder(position: position, lhs: $0, rhs: $1)
        }).first
    }
    
    // Returns true if lhs is a more desirable move than rhs.
    private static func areInDecreasingOrder(
        position: GamePosition,
        lhs: Move,
        rhs: Move
    ) -> Bool {
        let lhsType = type(position: position, move: lhs)
        let rhsType = type(position: position, move: rhs)
        if lhsType == rhsType {
            // If they're the same type, prefer the move closer to the end of the board.
            return lhs.from > rhs.from
        } else {
            return lhsType.rawValue > rhsType.rawValue
        }
    }
    
    private static func type(position: GamePosition, move: Move) -> MoveType {
        if Ur.isShared(space: move.to) && position.defender.occupies(space: move.to) {
            return .capturePiece
        }
        if Ur.isRosette(space: move.to) {
            return .occupyRosette
        }
        if move.to == Ur.pieceCount {
            return .exitBoard
        }
        if move.from < 0 {
            return .enterBoard
        }
        return .simple
    }
}

// Chooses a move at random.
final class RandomStrategy: Strategy {
    init() { }

    func getMove(position: GamePosition, roll: Int) -> Move? {
        position.moves(forRoll: roll).randomElement()
    }
}
