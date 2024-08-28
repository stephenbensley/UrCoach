//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import CheckersKit

// Implements the state machine for a complete game of Ur.
final class GameModel: Codable {
    // Next player to move
    private(set) var playerToMove = PlayerColor.random
    // Result of the most recent roll of the dice.
    private(set) var whiteDice = [Int](repeating: 0, count: Ur.diceCount)
    private(set) var blackDice = [Int](repeating: 0, count: Ur.diceCount)
    // Current game position
    private var position = GamePosition()
    
    var isInitial: Bool { return position == GamePosition() }
    
    // Returns true if the game is over.
    var isOver: Bool { position.terminal }
    
    // Returns the winner
    var winner: PlayerColor {
        assert(isOver)
        // When the game is over, the player to move is the loser.
        return playerToMove.other
    }
    
    init() { }
    
    func position(for player: PlayerColor? = nil) -> PlayerPosition {
        let player = player ?? playerToMove
        if player == playerToMove {
            return position.attacker
        } else {
            return position.defender
        }
    }
    
    func dice(for player: PlayerColor? = nil) -> [Int] {
        switch player ?? playerToMove {
        case .white:
            return whiteDice
        case .black:
            return blackDice
        }
    }
    
    func roll(for player: PlayerColor? = nil) -> Int {
        dice(for: player).reduce(0, +)
    }
    
    func moves(forRoll roll: Int) -> [Move] {
        position.moves(forRoll: roll)
    }
    
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
    
    func newGame() {
        position = GamePosition()
        
        var whiteRoll, blackRoll: Int
        repeat {
            whiteRoll = Self.rollDice(dice: &whiteDice)
            blackRoll = Self.rollDice(dice: &blackDice)
        } while whiteRoll == blackRoll
        
        playerToMove = whiteRoll > blackRoll ? .white : .black
    }
    
    func rollDice() -> Int {
        switch playerToMove {
        case .white:
            return Self.rollDice(dice: &whiteDice)
        case .black:
            return Self.rollDice(dice: &blackDice)
        }
    }
    
    private static func rollDice(dice: inout [Int]) -> Int {
        for i in dice.indices {
            dice[i] = Int.random(in: (0...1))
        }
        let roll = dice.reduce(0, +)
        return roll
    }
}
