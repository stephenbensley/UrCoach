// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import Foundation
import CheckersKit

// App model for the UrCoach app.
final class UrModel: Codable {
    let game: GameModel
#if TEST_NETWORK_FAULTS
    let analyzer = SolutionDB(client: FaultyDBClient(errorRate: 3, extraLatency: 5.0))
#else
    let analyzer = SolutionDB(client: CloudDBClient())
#endif
    var playerType: [PlayerType] = [ .human, .computer ]

    static func create() -> UrModel {
        if let data = UserDefaults.standard.data(forKey: "AppModel"),
           let model = try? JSONDecoder().decode(UrModel.self, from: data) {
            return model
        }
        // If we can't restore the app model, just create a new default one.
        return UrModel()
    }

    func newGame(white: PlayerType, black: PlayerType) {
        game.newGame()
        playerType[PlayerColor.white.rawValue] = white
        playerType[PlayerColor.black.rawValue] = black
    }

    func save() {
        let data = try! JSONEncoder().encode(self)
        UserDefaults.standard.set(data, forKey: "AppModel")
    }
    
    enum CodingKeys: String, CodingKey {
        case game
        case playerType
    }

    private init() {
        game = GameModel()
    }
}
