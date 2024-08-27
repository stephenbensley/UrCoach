//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SpriteKit
import SwiftUI

// Presents the SpriteKit game scene
struct GameView: View {
    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: GameScene(size: geo.size))
        }
        .edgesIgnoringSafeArea(.all)
    }
}
