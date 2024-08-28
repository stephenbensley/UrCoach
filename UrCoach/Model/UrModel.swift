// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SwiftUI
import CheckersKit

final class UrModel: Codable {
    let game: GameModel
    var playerType: [PlayerType] = [ .human, .computer ]

    func newGame(white: PlayerType, black: PlayerType) {
        game.newGame()
        playerType[PlayerColor.white.rawValue] = white
        playerType[PlayerColor.black.rawValue] = black
    }

    static func create() -> UrModel {
        if let data = UserDefaults.standard.data(forKey: "AppModel"),
           let model = try? JSONDecoder().decode(UrModel.self, from: data) {
            return model
        }
        
        // If we can't restore the app model, just create a new default one.
        return UrModel()
    }
    
    func save() {
        let data = try! JSONEncoder().encode(self)
        UserDefaults.standard.set(data, forKey: "AppModel")
    }
    
    private init() {
        game = GameModel()
    }
}

private struct AppModelKey: EnvironmentKey {
    static let defaultValue = UrModel.create()
}

extension EnvironmentValues {
    var appModel: UrModel {
        get { self[AppModelKey.self] }
        set { self[AppModelKey.self] = newValue }
    }
}

extension View {
    func appModel(_ value: UrModel) -> some View {
        environment(\.appModel, value)
    }
}
