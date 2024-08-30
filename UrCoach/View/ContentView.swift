//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SwiftUI
import SpriteKit

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
    @State private var scene: GameScene = GameScene()
    
    var body: some View {
        ZStack {
            Color(.background)
                .edgesIgnoringSafeArea(.all)
            switch mainView {
            case .menu:
                MenuView(changeView: changeView)
            case .game:
                GeometryReader { proxy in
                    SpriteView(scene: getScene(size: proxy.size))
                }
                .edgesIgnoringSafeArea(.all)
            case .rules:
                RulesView(changeView: changeView)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive { UrModel.shared.save() }
        }
    }
     
    private func changeView(_ newValue: ViewType) {
        withAnimation { mainView = newValue }
    }

    private func getScene(size: CGSize) -> GameScene {
        scene.addedToView(size: size, changeView: changeView)
        return scene
    }
}

#Preview {
    ContentView()
}
