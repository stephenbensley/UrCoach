//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    // Used to trigger saving state when app goes inactive.
    @Environment(\.scenePhase) private var scenePhase
    @State private var mainView = ViewType.menu
    @State private var delegate: CheckersGame

    init(delegate: some CheckersGame) {
        self.delegate = delegate
    }

    var body: some View {
        ZStack {
            Color(.background)
                .edgesIgnoringSafeArea(.all)
            switch mainView {
            case .menu:
                MenuView(delegate: delegate, changeView: changeView)
            case .game:
                GeometryReader { proxy in
                    SpriteView(scene: delegate.getScene(size: proxy.size, changeView: changeView))
                }
                .edgesIgnoringSafeArea(.all)
            case .rules:
                RulesView(changeView: changeView)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive { delegate.save() }
        }
    }
     
    private func changeView(_ newValue: ViewType) {
        withAnimation { mainView = newValue }
    }
}

#Preview {
    ContentView(delegate: MockDelegate())
}
