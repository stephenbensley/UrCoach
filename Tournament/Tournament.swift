//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import Foundation

@main
final class Tournament {
    
    static func playGame(players: [Strategy]) async throws -> Int {
        let game = GameModel()
        game.decideFirstPlayer()
        repeat {
            game.rollDice()
            let player = game.currentPlayer.rawValue
            let move = try await players[player].getMove(
                position: game.position,
                roll: game.diceSum
            )
            game.makeMove(move: move)
        } while !game.isOver
        return game.winner.rawValue
    }
    
    static func playTournament(players: [Strategy], gameCount: Int) async throws -> Double {
        var wins = [0, 0]
        for _ in 0..<gameCount {
            try await wins[playGame(players: players)] += 1
        }
        return 100.0 * Double(wins[0]) / Double(gameCount)
    }
    
    static func main() async {
        guard let solution = PositionValues(fileURLWithPath: "urSolution.data") else {
            print("Unable to load urSolution.data")
            return
        }
        
        let playerH = HeuristicStrategy()
        let playerR = RandomStrategy()
        let playerL = AnalysisStrategy(analyzer: solution)
        let playerC = AnalysisStrategy(analyzer: SolutionDB(client: MockDBClient(solution: solution)))
        var winPct = 0.0
        
        do {
            winPct = try await playTournament(players: [playerH, playerR], gameCount: 10000)
            print(String(format: "Heuristic vs. Random: %5.2f%%", winPct))

            winPct = try await playTournament(players: [playerL, playerH], gameCount: 10000)
            print(String(format: "Local Optimal vs. Heuristic: %5.2f%%", winPct))

            winPct = try await playTournament(players: [playerC, playerH], gameCount: 10000)
            print(String(format: "Mock Cloud Optimal vs. Heuristic: %5.2f%%", winPct))
        } catch {
            print("Unexpected error during tournament.")
        }
    }
}
