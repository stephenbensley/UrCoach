//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import SpriteKit
import SwiftUI

public extension CGSize {
    var aspectRatio: CGFloat {
        return height / width
    }
}

public extension Color {
    init(hex: Int) {
        let r = Double((hex & 0xff0000) >> 16) / 255
        let g = Double((hex & 0x00ff00) >>  8) / 255
        let b = Double((hex & 0x0000ff)      ) / 255
        self.init(red: r, green: g, blue: b)
    }
}

public extension SKScene {
    // Computes the minimal enclosing size with the specified aspect ratio.
    static func enclosingSize(aspectRatio: CGFloat, minSize: CGSize) -> CGSize {
        // Final size can't be smaller than noClip
        var result = minSize
        if aspectRatio > minSize.aspectRatio {
            // Target is skinnier, so stretch the height
            result.height = result.width * aspectRatio
        } else {
            // Target is fatter, so stretch the width
            result.width = result.height / aspectRatio
        }
        return result
    }
}

struct Palette {
    static let background = Color(.background)
}

final class GameScene: SKScene {
    private let board = GameBoard()
    
    override init(size: CGSize) {
        let size = Self.enclosingSize(
            aspectRatio: size.aspectRatio,
            minSize: CGSize(width: 390, height: 750)
        )
        super.init(size: size)
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.backgroundColor = UIColor(Palette.background)
        self.scaleMode = .aspectFit

        addChild(board)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
