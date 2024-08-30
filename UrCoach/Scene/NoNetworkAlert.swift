//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SpriteKit
import CheckersKit

class NoNetworkAlert: SKNode {
    enum Choice {
        case tryAgain
        case quit
    }
    typealias OnSelection = (Choice) -> Void
    
    let onSelection: OnSelection

    init(onSelecton: @escaping OnSelection) {
        self.onSelection = onSelecton
        super.init()
 
        let title = SKLabelNode()
        title.text = "Can't Connect to Server"
        title.fontSize = 18.0
        title.fontName = "Helvetica-Bold"

        let body = SKLabelNode()
        body.text = "An Internet connection is required to play against the computer."
        body.lineBreakMode = .byWordWrapping
        body.preferredMaxLayoutWidth = 200.0
        body.numberOfLines = 0
        body.fontSize = 15.0
        body.fontName = "Helvetica"
        
        let tryAgain = SKButton("Try Again", size: .init(width: 150.0, height: 55.0))
        let mainMenu = SKButton("Quit", size: .init(width: 150.0, height: 55.0))
        
        let background = SKShapeNode(rectOf: .init(width: 265.0, height: 300.0), cornerRadius: 18.0)
        background.lineWidth = 5.0
        background.fillColor = GamePalette.background
        addChild(background)
        
        title.position = .init(x: 0, y: 100)
        background.addChild(title)

        body.position = .init(x: 0, y: 30)
        background.addChild(body)

        tryAgain.position = .init(x: 0, y: -20)
        background.addChild(tryAgain)
        
        mainMenu.position = .init(x: 0, y: -95)
        background.addChild(mainMenu)
        self.zPosition = 100.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buttonAction(choice: Choice) {
        onSelection(choice)
    }
}
