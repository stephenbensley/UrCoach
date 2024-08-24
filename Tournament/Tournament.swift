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
        guard let solution = PositionValues(fileURLWithPath: "urSolution.data") else {
            print("Unable to load urSolution.data")
            return
        }
        
        let playerH = HeuristicStrategy()
        let playerR = RandomStrategy()
        let playerA = AnalysisStrategy(analyzer: solution)
        
        var winPct = 0.0
        
        do {
            winPct = try playTournament(players: [playerH, playerR], gameCount: 10000)
            print(String(format: "Heuristic vs. Random:  %5.2f%%", winPct))

            winPct = try playTournament(players: [playerA, playerH], gameCount: 10000)
            print(String(format: "Optimal vs. Heuristic: %5.2f%%", winPct))
        } catch {
            print("Unexpected error during tournament.")
        }
    }
}
