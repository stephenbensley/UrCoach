//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SwiftUI
import CheckersKit

// Signals which view to display.
enum ViewType {
    case menu
    case game
    case rules
}
// Callback to change the current view
typealias ChangeView = (ViewType) -> Void

struct ContentView: View {
    // Used to trigger saving state when app goes inactive.
    @Environment(\.scenePhase) private var scenePhase
    @State private var mainView = ViewType.menu
    @State private var appModel: UrModel
    @State private var scene: GameScene
    
    init() {
        let appModel = UrModel.create()
        let scene = GameScene(appModel: appModel)
        self.appModel = appModel
        self.scene = scene
    }

    var body: some View {
        ZStack {
            Color(.background)
                .edgesIgnoringSafeArea(.all)
            switch mainView {
            case .menu:
                MenuView(appModel: appModel, changeView: changeView)
            case .game:
                AutoSizedSpriteView(scene: getScene())
            case .rules:
                RulesView(changeView: changeView)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive { appModel.save() }
        }
    }
    
    func changeView(_ newValue: ViewType) {
        withAnimation { mainView = newValue }
    }
    
    func getScene() -> GameScene {
        scene.changeView = changeView
        return scene
    }
}

#Preview {
    ContentView()
}
