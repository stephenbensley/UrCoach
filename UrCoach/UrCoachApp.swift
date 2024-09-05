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
    private let model: UrModel
    private let scene: GameScene

    init() {
        let model = UrModel.create()
        self.model = model
        self.scene = GameScene(appModel: model)
    }

    // AppInfo protocol
    var appStoreId: Int = 6670455978
    var copyright: String = "© 2024 Stephen E. Bensley"
    var description: String = "Sharpen your skills by playing the Royal Game of Ur against an expert."
    var gitHubAccount: String = "stephenbensley"
    var gitHubRepo: String = "UrCoach"
    
    // CheckersGame protocol
    func getScene(size: CGSize, exitGame: @escaping () -> Void) -> SKScene {
        scene.addedToView(size: size, exitGame: exitGame)
        return scene
    }
    func newGame(white: CheckersKit.PlayerType, black: CheckersKit.PlayerType) {
        model.newGame(white: white, black: black)
    }
    func save() {
        model.save()
    }
    
    static let shared = UrGame()
}

@main
struct UrCoachApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(game: UrGame.shared)
        }
    }
}
