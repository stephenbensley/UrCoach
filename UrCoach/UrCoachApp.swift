//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SwiftUI
import CheckersKit
import SpriteKit

class UrGame: CheckersGame {
    private var scene = GameScene()

    var name: String = "Ur Coach"
    var description: String = "Sharpen your skills by playing the Royal Game of Ur with an expert."
    var privacyPolicy: URL = URL(string: "https://stephenbensley.github.io/UrCoach/privacy.html")!
    
    func getScene(size: CGSize, exitGame: @escaping () -> Void) -> SKScene {
        scene.addedToView(size: size, exitGame: exitGame)
        return scene
    }
    
    func newGame(white: CheckersKit.PlayerType, black: CheckersKit.PlayerType) {
        UrModel.shared.newGame(white: white, black: black)
    }
    
    func save() {
        UrModel.shared.save()
    }
}

@main
struct UrCoachApp: App {
    private var game = UrGame()
    
    var body: some Scene {
        WindowGroup {
            ContentView(game: game)
        }
    }
}
