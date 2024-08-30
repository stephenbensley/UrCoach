//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SpriteKit
import CheckersKit

// Alerts the user that a network error occurred and prompts them to try again or quit.
class NoNetworkAlert: SKNode {
    // User's choice.
    enum Choice {
        case tryAgain
        case quit
    }
    typealias OnSelection = (Choice) -> Void
    
    // Min/max Y used for sliding the bottom sheet in and out.
    private var minY: CGFloat = 0.0
    private var maxY: CGFloat = 0.0
    // Callback to report the user's selection.
    private var onSelection: OnSelection? = nil

    init(_ text: String, sceneSize: CGSize) {
        super.init()

        let title = SKLabelNode()
        title.text = "Can't Connect to Server"
        title.fontSize = 18.0
        title.fontName = "Helvetica-Bold"

        let body = SKLabelNode()
        body.text = text
        body.lineBreakMode = .byWordWrapping
        body.preferredMaxLayoutWidth = 340.0
        body.numberOfLines = 0
        body.fontSize = 15.0
        body.fontName = "Helvetica"
        
        let tryAgain = SKButton("Try Again", size: .init(width: 125, height: 45))
        tryAgain.action = { self.buttonAction(choice: .tryAgain) }
        let mainMenu = SKButton("Quit", size: .init(width: 125, height: 45))
        mainMenu.action = { self.buttonAction(choice: .quit) }

        let mySize = CGSize(width: sceneSize.width, height: 300.0)
        self.minY = -0.5 * (mySize.height + sceneSize.height)
        self.maxY = minY + mySize.height

        let background = SKShapeNode(rectOf: mySize)
        background.lineWidth = 0.0
        background.fillColor = GamePalette.bottomSheet
        addChild(background)
        
        title.position = .init(x: 0, y: 100)
        background.addChild(title)

        body.position = .init(x: 0, y: 40)
        background.addChild(body)

        tryAgain.position = .init(x: 0, y: -15)
        background.addChild(tryAgain)
        
        mainMenu.position = .init(x: 0, y: -80)
        background.addChild(mainMenu)

        self.position = .init(x: 0.0, y: minY)
        self.zPosition = Layer.alerts
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func display(onSelection: @escaping OnSelection) {
        self.onSelection = onSelection
        run(SKAction.moveTo(y: maxY, duration: 0.35))
    }

    private func buttonAction(choice: Choice) {
        run(SKAction.moveTo(y: minY, duration: 0.35)) { [onSelection] in
            onSelection?(choice)
        }
    }
}
