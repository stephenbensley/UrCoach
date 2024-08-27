//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SpriteKit
import SwiftUI
import CheckersKit

final class GameScene: SKScene {
    private let board = GameBoard(onMoveSelected: { _ in } )
    private let locations = BoardLocations()
    private let whiteDice: RollingDice
    private let blackDice: RollingDice
    
    override init(size: CGSize) {
        self.whiteDice = RollingDice(diceCount: Ur.diceCount, orientation: .vertical)
        self.blackDice = RollingDice(diceCount: Ur.diceCount, orientation: .vertical)
        
        let minSize = CGSize(width: 390, height: 750)
        super.init(size: minSize.stretchToAspectRatio(size.aspectRatio))
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.backgroundColor = GamePalette.background
        self.scaleMode = .aspectFit
        
        addChild(board)
        
        for i in 0...Ur.spaceCount {
            addTarget(player: .white, index: i)
            if !Ur.isShared(space: i) {
                addTarget(player: .black, index: i)
            }
        }
        for i in 0..<Ur.pieceCount {
            addWaitingChecker(player: .white, index: i)
            addWaitingChecker(player: .black, index: i)
        }
       
        whiteDice.position = .init(x: -135.0, y: 135.0)
        addChild(whiteDice)
        blackDice.position = .init(x: +135.0, y: 135.0)
        addChild(blackDice)

        let button = SKButton("Roll", size: .init(width: 150, height: 55)) { }
        button.position = CGPoint(x: 0, y: -310)
        addChild(button)
        
        whiteDice.rollOnTap(newValues: (0..<4).map({ _ in Int.random(in: 0...1) })) {
        }
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addTarget(player: PlayerColor, index: Int) {
        board.addChild(
            BoardTarget(
                position: locations.position(
                    player: player,
                    index: .inPlay(index)
                )
            )
        )
    }

    private func addWaitingChecker(player: PlayerColor, index: Int) {
        board.addChild(
            Checker(
                player: player,
                position: locations.position(
                    player: player,
                    index: .waiting(index)
                )
            )
        )
    }
}
