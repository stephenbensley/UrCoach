//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SwiftUI
import CheckersKit
import SpriteKit

// Provides the app-specific properties and methods consumed by the CheckersKit framework.
class UrGame: CheckersGame {
    private let model = UrModel.create()
    private var scene: GameScene!

    // AppInfo protocol
    let appStoreId: Int = 6670455978
    let copyright: String = "© 2024 Stephen E. Bensley"
    let description: String = "Sharpen your skills by playing the Royal Game of Ur against an expert."
    let gitHubAccount: String = "stephenbensley"
    let gitHubRepo: String = "UrCoach"
    
    // CheckersGame protocol
    func getScene(size: CGSize, exitGame: @escaping () -> Void) -> SKScene {
        // We defer initialization since SKScene must be initialized from MainActor
        if scene == nil {
            scene = GameScene(appModel: model)
        }
        scene.addedToView(size: size, exitGame: exitGame)
        return scene
    }
    func newGame(white: PlayerType, black: PlayerType) {
        model.newGame(white: white, black: black)
    }
    func save() {
        model.save()
    }
}

@main
struct UrCoachApp: App {
    private let game = UrGame()

    var body: some Scene {
        WindowGroup {
            ContentView(game: game)
        }
    }
}
