//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

public enum PlayerColor: Int, CaseIterable, Codable {
    case white
    case black
    
    var other: PlayerColor {
        switch self {
        case .white:
            return .black
        case .black:
            return .white
        }
    }
    
    static var random: PlayerColor {
        allCases.randomElement()!
    }
}

// Represents a game of Ur
public final class GameModel {
    public private(set) var playerToMove = PlayerColor.random
    public private(set) var position = GamePosition()
    public private(set) var dice = [Int](repeating: 0, count: Ur.diceCount)

    // Returns true if the game is over.
    public var isOver: Bool { position.terminal }

    public var winner: PlayerColor { playerToMove.other }

    public init() { }
    
    // Updates game state based on the specified move.
    public func makeMove(move: Move?) {
        if let move = move {
            if position.makeMove(move) {
                playerToMove = playerToMove.other
            }
        } else {
            position = position.reversed
            playerToMove = playerToMove.other
        }
    }
    
    public func rollDice() -> Int {
        for i in dice.indices {
            dice[i] = Int.random(in: (0...1))
        }
        let roll = dice.reduce(0, +)
        return roll
    }
}
