//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SpriteKit
import SwiftUI
import CheckersKit
import UtiliKit

final class GameScene: SKScene {
    // Used to return the app to the main menu
    @Binding var mainView: ViewType
    // Next two members are copied from the model. They are referenced so frequently, that
    // it's convenient to copy them out of the QueahModel struct.
    private let game: GameModel
    private var playerType: [PlayerType]
    private let positions = BoardPositions()
    private let board = GameBoard()
    private let whiteDice = RollingDice(diceCount: Ur.diceCount, orientation: .vertical)
    private let blackDice = RollingDice(diceCount: Ur.diceCount, orientation: .vertical)
    private var pendingDice = [Int]()
    private var moves = [Move]()
    
    init(viewType: Binding<ViewType>, size: CGSize, model: UrModel) {
        self._mainView = viewType
        self.game = model.game
        self.playerType = model.playerType
        
        let minSize = CGSize(width: 390, height: 750)
        super.init(size: minSize.stretchToAspectRatio(size.aspectRatio))
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.backgroundColor = GamePalette.background
        self.scaleMode = .aspectFit
        
        addChild(board)
        
        addTargets()
        setupPieces(player: .white, pieces: game.playerPosition(for: .white))
        setupPieces(player: .black, pieces: game.playerPosition(for: .black))
        
        whiteDice.position = .init(x: -135.0, y: 135.0)
        whiteDice.setValues(game.whiteDice)
        addChild(whiteDice)
        blackDice.position = .init(x: +135.0, y: 135.0)
        blackDice.setValues(game.blackDice)
        addChild(blackDice)
        
        self.moves = game.moves(forRoll: game.diceSum)
    
        let button = SKButton("Menu", size: .init(width: 150, height: 55), action: returnToMainMenu)
        button.position = CGPoint(x: 0, y: -310)
        addChild(button)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        switch game.state {
        case .decideFirstPlayer:
            decideFirstPlayer()
        case .rollDice:
            rollDice()
        case .makeMove:
            pickMove()
        case .gameOver:
            displayOutcome()
        }
    }
    
    private func addTargets() {
        for i in 0...Ur.spaceCount {
            let pos = positions.position(.white, i)
            board.addTarget(at: pos)
            if !Ur.isShared(space: i) {
                board.addTarget(at: pos.reflectedOverY)
            }
        }
    }
    
    private func setupPieces(player: PlayerColor, pieces: PlayerPosition) {
        for i in 0..<pieces.waitCount {
            let pos = positions.position(player, i - BoardPositions.indexOffset)
            board.addChecker(for: player, at: pos)
        }
        
        for i in 0..<Ur.spaceCount where pieces.occupies(space: i) {
            let pos = positions.position(player, i)
            board.addChecker(for: player, at: pos)
        }
    }
    
    private func decideFirstPlayer() {
        game.decideFirstPlayer()
        let multiComplete = MultiComplete(waitCount: 2, completion: self.displayStartingPlayer)
        whiteDice.roll(newValues: game.whiteDice, completion: multiComplete.complete)
        blackDice.roll(newValues: game.blackDice, completion: multiComplete.complete)
    }
    
    private func displayStartingPlayer() {
        let alert = AutoAlert("\(game.currentPlayer) moves first")
        addChild(alert)
        alert.display(completion: self.rollDice)
    }
    
    private func rollDice() {
        // Roll the dice and update the available moves based on the outcome.
        pendingDice = GameModel.rollDice()
        moves = game.moves(forRoll: pendingDice.reduce(0, +))

        // Animate the roll of the dice.
        switch game.currentPlayer {
        case .white:
            whiteDice.rollOnTap(newValues: pendingDice, completion: rollComplete)
        case .black:
            blackDice.rollOnTap(newValues: pendingDice, completion: rollComplete)
        }
    }
    
    private func rollComplete() {
        game.rollDice(dice: pendingDice)
        if moves.isEmpty {
            displayNoMove()
        } else {
            pickMove()
        }
    }
    private func displayNoMove() {
         let alert = AutoAlert("\(game.currentPlayer) has no move")
        addChild(alert)
        game.makeMove(move: nil)
        alert.display(completion: rollDice)
    }
    
    private func pickMove() {
         board.pickMove(
            for: game.currentPlayer,
            moves: moves.map(convertMove),
            onMovePicked: onMovePicked
        )
    }
    
    private func returnToMainMenu() {
        mainView = .menu
    }

    private func onMovePicked(checker: Checker, viewMove: GameBoard.Move) {
        guard let modelMove = viewMove.userData as? Move else { return }
        
        var actions = [SKAction]()
        actions.append(SKAction.setLayer(Layer.moving, onTarget: checker))
        
        if modelMove.from < 0 {
            let entry = positions.position(game.currentPlayer, -1)
            actions.append(SKAction.move(to: entry, duration: 1.0))
        }
        
        for i in (modelMove.from + 1)...modelMove.to {
            let entry = positions.position(game.currentPlayer, i)
            actions.append(SKAction.move(to: entry, duration: 0.5))
        }
        
        if modelMove.to == Ur.spaceCount {
            actions.append(SKAction.fadeOut(withDuration: 0.5))
            actions.append(SKAction.removeFromParent())
        }
        
        if let captured = board.checker(at: viewMove.to) {
            let action = captureAction(captured: captured)
            actions.append(SKAction.run { captured.run(action) })
        }

        actions.append(SKAction.setLayer(Layer.checkers, onTarget: checker))
        
        let completion = Ur.isRosette(space: modelMove.to) ? displayRollAgain : rollDice
        checker.run(SKAction.sequence(actions), completion: completion)
        
        game.makeMove(move: modelMove)

    }

    private func captureAction(captured: Checker) -> SKAction {
        let player = captured.player
        let waitCount = game.playerPosition(for: player).waitCount
        let to = positions.position(player, waitCount - BoardPositions.indexOffset)
        return SKAction.sequence([
            SKAction.setLayer(Layer.captured, onTarget: captured),
            SKAction.move(to: to, duration: 1.0),
            SKAction.setLayer(Layer.checkers, onTarget: captured)
       ])
    }
    
    private func displayRollAgain() {
        let alert = AutoAlert("\(game.currentPlayer) rolls again")
        addChild(alert)
        alert.display(completion: rollDice)
    }
    
    private func displayOutcome() {
         let alert = AutoAlert("\(game.winner) wins!")
        addChild(alert)
        alert.display(completion: doNothing)
    }
    
    private func doNothing() { }

    private func indexToPoint(_ index: Int) -> CGPoint {
        let shifted: Int
        if index < 0 {
            shifted = index + game.playerPosition().waitCount - BoardPositions.indexOffset
        } else {
            shifted = index
        }
        return positions.position(game.currentPlayer, shifted)
    }
    
    private func convertMove(_ move: Move) -> GameBoard.Move {
        return .init(
            from: indexToPoint(move.from),
            to: indexToPoint(move.to),
            userData: move
        )
    }
}
