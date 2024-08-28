//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SwiftUI

// Signals which view to display.
enum ViewType {
    case menu
    case game
    case rules
}

struct ContentView: View {
    // Used to trigger saving state when app goes inactive.
    @Environment(\.scenePhase) private var scenePhase
    @State private var appModel = UrModel.create()
    @State private var mainView = ViewType.menu
    
    var body: some View {
        ZStack {
            Color(.background)
                .edgesIgnoringSafeArea(.all)
            switch mainView {
            case .menu:
                MenuView(mainView: $mainView.animation())
            case .game:
                GameView(mainView: $mainView.animation())
            case .rules:
                RulesView(mainView: $mainView.animation())
            }
        }
        .appModel(appModel)
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive { appModel.save() }
        }
    }
}

#Preview {
    ContentView()
}
