//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

// Used to represent the players in the game.
enum PlayerColor: Int, CaseIterable, Codable {
    case white
    case black
    
    // Returns the other color -- useful for switching sides.
    var other: PlayerColor {
        switch self {
        case .white:
            return .black
        case .black:
            return .white
        }
    }
    
    // Choose a color at random -- useful for starting the game.
    static var random: PlayerColor {
        allCases.randomElement()!
    }
}

// Implements the state machine for a complete game of Ur.
final class GameModel {
    // Next player to move
    private(set) var playerToMove = PlayerColor.random
    // Current game position
    private(set) var position = GamePosition()
    // Result of the most recent roll of the dice.
    private(set) var dice = [Int](repeating: 0, count: Ur.diceCount)

    // Returns true if the game is over.
    var isOver: Bool { position.terminal }

    // Returns the winner
    var winner: PlayerColor {
        assert(isOver)
        // When the game is over, the player to move is the loser.
        return playerToMove.other
    }

    init() { }
    
    // Updates game state based on the specified move. nil indicates no move available.
    func makeMove(move: Move?) {
        if let move = move {
            if position.makeMove(move) {
                playerToMove = playerToMove.other
            }
        } else {
            position = position.reversed
            playerToMove = playerToMove.other
        }
    }
    
    func rollDice() -> Int {
        for i in dice.indices {
            dice[i] = Int.random(in: (0...1))
        }
        let roll = dice.reduce(0, +)
        return roll
    }
}
