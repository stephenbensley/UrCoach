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
        setupPieces(player: .white, pieces: game.position(for: .white))
        setupPieces(player: .black, pieces: game.position(for: .black))
        
        whiteDice.position = .init(x: -135.0, y: 135.0)
        addChild(whiteDice)
        blackDice.position = .init(x: +135.0, y: 135.0)
        addChild(blackDice)
        
        let button = SKButton("Menu", size: .init(width: 150, height: 55)) { }
        button.position = CGPoint(x: 0, y: -310)
        addChild(button)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        if game.isInitial {
            decideStartingPlayer()
        } else {
            nextMove()
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
    
    private func nextMove() { }
    
    private func decideStartingPlayer() {
        let multiComplete = MultiComplete(waitCount: 2, completion: self.displayStartingPlayer)
        whiteDice.roll(newValues: game.whiteDice, completion: multiComplete.complete)
        blackDice.roll(newValues: game.blackDice, completion: multiComplete.complete)
    }
    
    private func displayStartingPlayer() {
        let alert = AutoAlert("\(game.playerToMove) has first move")
        addChild(alert)
        alert.display(completion: self.rollDice)
    }
    
    private func rollDice() {
        // Roll the dice and update the available moves based on the outcome.
        moves = game.moves(forRoll: game.rollDice())
        // Determine next action
        let completion = moves.isEmpty ? displayNoMove : selectMove
        
        // Animate the roll of the dice.
        switch game.playerToMove {
        case .white:
            whiteDice.rollOnTap(newValues: game.dice(), completion: completion)
        case .black:
            blackDice.rollOnTap(newValues: game.dice(), completion: completion)
        }
    }
    
    private func displayNoMove() {
        let alert = AutoAlert("\(game.playerToMove) has no move")
        addChild(alert)
        game.makeMove(move: nil)
        alert.display(completion: rollDice)
    }
    
    private func selectMove() {
        board.selectMove(
            for: game.playerToMove,
            moves: moves.map(convertMove),
            onMoveSelected: onMoveSelected
        )
    }
    
    private func onMoveSelected(_ moveIndex: Int) { }
    
    
    private func indexToPoint(_ index: Int) -> CGPoint {
        let shifted: Int
        if index < 0 {
            shifted = index + game.position().waitCount - BoardPositions.indexOffset
        } else {
            shifted = index
        }
        return positions.position(game.playerToMove, shifted)
    }
    
    private func convertMove(_ move: Move) -> GameBoard.Move {
        return .init(from: indexToPoint(move.from), to: indexToPoint(move.to))
    }
}
