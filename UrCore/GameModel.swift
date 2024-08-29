//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import CheckersKit

// Implements the state machine for a complete game of Ur.
final class GameModel: Codable {
    enum State: Codable {
        case decideFirstPlayer
        case rollDice
        case makeMove
        case gameOver
    }
    // Current state of the game. Useful for error checking and for resuming a saved game.
    private(set) var state = State.decideFirstPlayer
    // Next player to move
    private(set) var currentPlayer = PlayerColor.white
    // Current game position
    private(set) var position = GamePosition()
    // Result of the most recent roll of the dice.
    private(set) var whiteDice = [Int](repeating: 0, count: Ur.diceCount)
    private(set) var blackDice = [Int](repeating: 0, count: Ur.diceCount)
    
    // Returns true if the game is over.
    var isOver: Bool { state == .gameOver }
    
    // Returns the winner
    var winner: PlayerColor {
        assert(isOver)
        // When the game is over, the player to move is the loser.
        return currentPlayer.other
    }

    // Position of the specified player or the current player if none specified.
    func playerPosition(for player: PlayerColor? = nil) -> PlayerPosition {
        let player = player ?? currentPlayer
        if player == currentPlayer {
            return position.attacker
        } else {
            return position.defender
        }
    }

    // Sum of the dice for the current player.
    var diceSum: Int {
        switch currentPlayer {
        case .white:
            return whiteDice.reduce(0, +)
        case .black:
            return blackDice.reduce(0, +)
        }
    }
    
    // Moves available to the current player.
    func moves(forRoll roll: Int) -> [Move] {
        position.moves(forRoll: roll)
    }
    
    // Start a new game.
    func newGame() {
        state = .decideFirstPlayer
        position = GamePosition()
    }
    
    // Roll the dice to determine who moves first.
    func decideFirstPlayer() {
        assert(state == .decideFirstPlayer)
        state = .rollDice
        
        var whiteSum, blackSum: Int
        repeat {
            whiteDice = Self.rollDice()
            whiteSum = whiteDice.reduce(0, +)
            
            blackDice = Self.rollDice()
            blackSum = blackDice.reduce(0, +)
        } while whiteSum == blackSum
        
        currentPlayer = whiteSum > blackSum ? .white : .black
    }
    
    // Roll the dice to determine the current player's moves.
    func rollDice(dice: [Int] = GameModel.rollDice()) {
        assert(state == .rollDice)
        state = .makeMove
        
        switch currentPlayer {
        case .white:
            whiteDice = dice
        case .black:
            blackDice = dice
        }
    }
    
    // Updates game state based on the specified move. nil indicates no move available.
    func makeMove(move: Move?) {
        assert(state == .makeMove)
        
        if let move = move {
            if position.makeMove(move) {
                currentPlayer = currentPlayer.other
            }
        } else {
            position = position.reversed
            currentPlayer = currentPlayer.other
        }
        
        state = position.terminal ? .gameOver : .rollDice
    }
    
    // Generate a random dice roll.
    static func rollDice() -> [Int] {
        (0..<Ur.diceCount).map {_ in Int.random(in: 0...1) }
    }
}
