//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import Foundation
import UrCore

@main
final class Tournament {
    
    static func playGame(players: [Strategy]) throws -> Int {
        let game = GameModel()
        repeat {
            let player = game.playerToMove.rawValue
            let roll = game.rollDice()
            let move = try players[player].getMove(position: game.position, roll: roll)
            game.makeMove(move: move)
        } while !game.isOver
        return game.winner.rawValue
    }
    
    static func playTournament(players: [Strategy], gameCount: Int) throws -> Double {
        var wins = [0, 0]
        for _ in 0..<gameCount {
            try wins[playGame(players: players)] += 1
        } 
        return 100.0 * Double(wins[0]) / Double(gameCount)
    }
    
    static func main() {
        let solution = PositionValues(fileURLWithPath: "urSolution.data")!
        let player1 = HeuristicStrategy()
        let player2 = RandomStrategy()
        let player3 = AnalysisStrategy(analyzer: solution)
        do {
            let winPct = try playTournament(players: [player3, player1], gameCount: 10000)
            print(winPct)
        } catch {
            
        }
    }
}
