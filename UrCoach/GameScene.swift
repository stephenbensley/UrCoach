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

public extension SKColor {
    static let analysisGreen = SKColor(Color(hex: 0x549C30))
    static let analysisRed   = SKColor(Color.red)
}

final class GameScene: SKScene {
    // Game coordinates are designed for this size.
    static private let minSize = CGSize(width: 390, height: 750)
    // Side length for the board spaces.
    static private let spaceLength = 55.0
    // Time it takes to move one space on the board
    static private let moveDuration = 0.35
    // SKNode names
    static private let annotationName = "annotation"
    
    // Global game state
    private let appModel: UrModel
    // Set by the enclosing SwiftUI view to allow this scene to return to the main menu.
    private var exitGame: (() -> Void)? = nil
    
    // Used to map logical board positions to screen coordinates.
    private let positions = BoardPositions()
    
    // These nodes are interacted with frequently, so we cache references to them.
    private let board = GameBoard()
    private let whiteDice = RollingDice(diceCount: Ur.diceCount, orientation: .vertical)
    private let blackDice = RollingDice(diceCount: Ur.diceCount, orientation: .vertical)
    private let analyzeButton = SKButton("Analyze", size: .init(width: 125, height: 45))
    private let menuButton = SKButton("Menu", size: .init(width: 125, height: 45))
    
    // Allowed moves for the current turn.
    private var allowedMoves = [Move]()
    
    // True if a human is playing solo against the computer.
    private var solo = false
    // Pending SolutionDB queries (if any).
    private var pendingBestMove: Task<Move?, Never>? = nil
    private var pendingAnalyze: Task<[MoveValue]?, Never>? = nil
    // Used to detect stale move analyses. If the user picks a move before the analysis query
    // completes, then the analysis isn't useful anymore.
    private var pickMoveEpoch = 0
    
    // Helpers for frequently accessed state.
    private var currentType: PlayerType { appModel.playerType[game.currentPlayer.rawValue] }
    private var game: GameModel { appModel.game }
    private var dice: RollingDice {
        switch game.currentPlayer {
        case .white:
            return whiteDice
        case .black:
            return blackDice
        }
    }
    
    // MARK: Initialization
    
    init(appModel: UrModel) {
        self.appModel = appModel
        super.init(size: Self.minSize)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.backgroundColor = .background
        self.scaleMode = .aspectFit
        
        // Add the permanent nodes.
        addChild(board)
        addTargets()
        whiteDice.position = .init(x: -135.0, y: 135.0)
        addChild(whiteDice)
        blackDice.position = .init(x: +135.0, y: 135.0)
        addChild(blackDice)
        analyzeButton.action = analyzeMoves
        analyzeButton.position = .init(x: +80.0, y: -310.0)
        addChild(analyzeButton)
        menuButton.action = returnToMainMenu
        menuButton.position =    .init(x: -80.0, y: -310.0)
        addChild(menuButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addTargets() {
        for i in 0...Ur.spaceCount {
            let pos = positions.position(.white, index: i)
            addTarget(at: pos)
            if !Ur.isShared(space: i) {
                addTarget(at: pos.reflectedOverY)
            }
        }
    }
    
    private func addTarget(at position: CGPoint) {
        let target = BoardTarget(sideLength: Self.spaceLength)
        target.position = position
        board.addChild(target)
    }
    
    // Invoked when we've been added to a SwiftUI view.
    func addedToView(size: CGSize, exitGame: @escaping () -> Void) {
        self.size = Self.minSize.stretchToAspectRatio(size.aspectRatio)
        self.exitGame = exitGame
    }
    
    // MARK: Clean-up
    
    // Returns to a clean state by stopping all ongoing activity and clearing the gameboard.
    private func returnToMainMenu() {
        pendingAnalyze?.cancel()
        pendingAnalyze = nil
        pendingBestMove?.cancel()
        pendingBestMove = nil
        
        whiteDice.removeAllActions()
        blackDice.removeAllActions()
        
        board.clear()
        
        exitGame?()
    }
    
    // MARK: Load state
    
    // Invoked when our scene is added to an SKView and will now be displayed.
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Load state from the app model. This might have changed since we were last displayed.
        loadAppModel()
        
        // Kick off the FSM based on the current game state.
        switch game.state {
        case .decideFirstPlayer:
            decideFirstPlayer()
        case .rollDice:
            rollDice()
        case .makeMove:
            pickMove()
        case .gameOver:
            displayGameOutcome()
        }
    }
    
    private func loadAppModel() {
        // Place the checkers on the board.
        board.clear()
        placeCheckers(player: .white, pieces: game.playerPosition(for: .white))
        placeCheckers(player: .black, pieces: game.playerPosition(for: .black))
        board.inputEnabled = true
        
        // Setup the dice.
        whiteDice.setValues(game.whiteDice)
        blackDice.setValues(game.blackDice)
        
        // Update derived properties.
        allowedMoves = game.moves()
        solo = appModel.playerType[0] != appModel.playerType[1]
        pickMoveEpoch += 1
        
        // Place the buttons based on whether we're in solo mode.
        if solo {
            analyzeButton.enabled = false
            analyzeButton.isHidden = false
            menuButton.position = .init(x: -80.0, y: -310.0)
        } else {
            analyzeButton.isHidden = true
            menuButton.position = .init(x: 0, y: -310.0)
        }
        
        // Start network I/O if necessary
        if solo && game.state == .makeMove {
            switch currentType {
            case .human:
                analyzeButton.enabled = true
                fetchAnalysis(forRoll: game.diceSum)
            case .computer:
                fetchBestMove(forRoll: game.diceSum)
            }
        }
    }
    
    private func placeCheckers(player: PlayerColor, pieces: PlayerPosition) {
        for i in 0..<pieces.waitCount {
            let pos = positions.position(player, waitSlot: i)
            placeChecker(for: player, at: pos)
        }
        
        for i in 0..<Ur.spaceCount where pieces.occupies(space: i) {
            let pos = positions.position(player, index: i)
            placeChecker(for: player, at: pos)
        }
    }
    
    private func placeChecker(for player: PlayerColor, at position: CGPoint) {
        let checker = Checker(player: player)
        checker.position = position
        board.addChild(checker)
    }
    
    // MARK: FSM entry points
    
    private func decideFirstPlayer() {
        game.decideFirstPlayer()
        let multiComplete = MultiComplete(waitCount: 2, completion: self.displayStartingPlayer)
        whiteDice.roll(newValues: game.whiteDice, completion: multiComplete.complete)
        blackDice.roll(newValues: game.blackDice, completion: multiComplete.complete)
    }
    
    private func displayStartingPlayer() {
        let alert = AutoAlert("\(game.currentPlayer) moves first")
        addChild(alert)
        alert.display(forDuration: 1.5, completion: self.rollDice)
    }
    
    private func rollDice() {
        // Roll the dice and update the available moves based on the outcome.
        game.rollDice()
        allowedMoves = game.moves()
        
        // Commpute the next state after the roll animation completes.
        let nextState = allowedMoves.isEmpty ? displayNoMove : pickMove
        
        // Initiate network I/O before animating the dice. This buys us some extra time to mask
        // network latency.
        if solo {
            switch currentType {
            case .human:
                fetchAnalysis(forRoll: game.diceSum)
            case .computer:
                fetchBestMove(forRoll: game.diceSum)
            }
        }
        
        // The animation looks nicer without the selection border.
        whiteDice.selected = false
        blackDice.selected = false
        dice.roll(newValues: game.diceValues, completion: nextState)
    }
    
    private func displayNoMove() {
        let alert = AutoAlert("\(game.currentPlayer) has no move")
        addChild(alert)
        game.makeMove(move: nil)
        alert.display(forDuration: 1.5, completion: rollDice)
    }
    
    private func pickMove() {
        // Enable the selection border to signal whose turn it is.
        dice.selected = true
        
        switch currentType {
        case .human:
            // During solo play, the human can ask for help.
            if solo { analyzeButton.enabled = true }
            board.pickMove(
                for: game.currentPlayer,
                allowedMoves: allowedMoves.map(convertMove),
                onMovePicked: executeMove
            )
        case .computer:
            pickBestMove(onMovePicked: executeMove)
        }
    }
    
    private func executeMove(checker: Checker, viewMove: GameBoard.Move) {
        guard let modelMove = viewMove.userData as? Move else { return }
        
        // Annotations have served their purpose, so they can be removed now.
        removeAnnotations()
        pickMoveEpoch += 1
        
        // Compute next state. Note: we can't update the game model until after the animations
        // have been constructed, so we use tryMove to peek at the next position.
        let (nextPosition, _) = game.position.tryMove(move: modelMove)
        let nextState: () -> Void
        if nextPosition.terminal {
            nextState = displayGameOutcome
        } else if Ur.isRosette(space: modelMove.to) {
            nextState = displayRollAgain
        } else {
            nextState = rollDice
        }
        
        // Build the animation before updating the game model. The animation needs to know the
        // current state of the game.
        let actions = buildMoveAnimation(
            checker: checker,
            viewMove: viewMove,
            completion: nextState
        )
        
        // Now we can update the model and run the animation.
        game.makeMove(move: modelMove)
        checker.run(SKAction.sequence(actions))
    }
    
    private func displayRollAgain() {
        let alert = AutoAlert("\(game.currentPlayer) rolls again")
        addChild(alert)
        alert.display(forDuration: 1.5, completion: rollDice)
    }
    
    private func displayGameOutcome() {
        let alert = AutoAlert("\(game.winner) wins!")
        addChild(alert)
        alert.display(forDuration: 5.0, completion: doNothing)
    }
    
    private func alertNetworkError(_ text: String, retryAction: @escaping () -> Void) {
        // Disable input -- it would be silly to let the user make a move while the alert
        // is showing.
        board.inputEnabled = false
        let alert = NoNetworkAlert(text, sceneSize: size)
        addChild(alert)
        alert.display() { choice in
            self.board.inputEnabled = true
            switch choice {
            case .tryAgain:
                retryAction()
            case .quit:
                self.returnToMainMenu()
            }
        }
    }
    
    private func doNothing() { }
    
    // MARK: Animations
    
    func buildMoveAnimation(
        checker: Checker,
        viewMove: GameBoard.Move,
        completion: @escaping () -> Void
    ) -> [SKAction] {
        guard let modelMove = viewMove.userData as? Move else { return .init() }
        
        var runBlock = completion
        
        var actions = [SKAction]()
        actions.append(SKAction.setLayer(Layer.moving, onTarget: checker))
        
        if modelMove.from < 0 {
            let entryPoint = positions.position(game.currentPlayer, index: -1)
            let duration = Self.entryExitDuration(from: checker.position, to: entryPoint)
            actions.append(SKAction.move(to: entryPoint, duration: duration))
        }
        
        for i in (modelMove.from + 1)...modelMove.to {
            let to = positions.position(game.currentPlayer, index: i)
            actions.append(SKAction.move(to: to, duration: Self.moveDuration))
        }
        
        if modelMove.to == Ur.spaceCount {
            actions.append(SKAction.fadeOut(withDuration: Self.moveDuration))
            actions.append(SKAction.removeFromParent())
        }
        
        if let captured = board.checker(at: viewMove.to) {
            runBlock = MultiComplete(waitCount: 2, completion: completion).complete
            let action = buildCaptureAnimation(captured: captured, runBlock: runBlock)
            actions.append(SKAction.run { captured.run(action) })
            actions.append(SKAction.wait(forDuration: Self.moveDuration))
        }
        
        actions.append(SKAction.setLayer(Layer.checkers, onTarget: checker))
        actions.append(SKAction.run(runBlock))
        
        return actions
    }
    
    private func buildCaptureAnimation(
        captured: Checker,
        runBlock: @escaping () -> Void
    ) -> SKAction {
        let player = captured.player
        let waitCount = game.playerPosition(for: player).waitCount
        let to = positions.position(player, waitSlot: waitCount)
        let duration = Self.entryExitDuration(from: captured.position, to: to)
        return SKAction.sequence([
            SKAction.setLayer(Layer.captured, onTarget: captured),
            SKAction.move(to: to, duration: duration),
            SKAction.setLayer(Layer.checkers, onTarget: captured),
            SKAction.run(runBlock)
        ])
    }
    
    static private func entryExitDuration(from: CGPoint, to: CGPoint) -> CGFloat {
        let deltaX = from.x - to.x
        let deltaY = from.y - to.y
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        let spaces = distance / Self.spaceLength
        return spaces * Self.moveDuration
    }
    
    // MARK: Annotations
    
    private func annotateCheckers(with analysis: [MoveValue]) {
        for (i, move) in analysis.enumerated() {
            annotateChecker(at: move.move.from, with: move.value, isBest: (i == 0))
        }
    }
    
    private func annotateChecker(at index: Int, with winProb: Float, isBest: Bool) {
        guard let checker = board.checker(at: indexToPoint(index)) else { return }
        
        let label = SKLabelNode()
        label.fontColor = isBest ? .analysisGreen : .analysisRed
        label.fontName = "Helvetica"
        label.fontSize = 11.0
        label.horizontalAlignmentMode = .center
        label.position = .init(x: 0, y: -5)
        label.text = String(format: "%.2f%%", 100.0 * winProb)
        
        let shape = SKShapeNode(rectOf: .init(width: 47.0, height: 15.0), cornerRadius: 2.0)
        shape.fillColor = .white
        shape.name = "annotation"
        shape.position = .init(x: 0.0, y: 27.5)
        shape.addChild(label)
        
        checker.addChild(shape)
    }
    
    private func removeAnnotations() {
        analyzeButton.enabled = false
        for child in board.children {
            if let checker = child as? Checker {
                checker.childNode(withName: "annotation")?.removeFromParent()
            }
        }
    }
    
    // MARK: SolutionDB operations
    
    private func fetchAnalysis(forRoll roll: Int) {
        pendingAnalyze?.cancel()
        pendingAnalyze = Task { @MainActor in
            try? await appModel.analyzer.analyze(
                position: game.position,
                roll: roll
            )
        }
    }
    
    private func fetchBestMove(forRoll roll: Int) {
        pendingBestMove?.cancel()
        pendingBestMove = Task{ @MainActor in
            try? await appModel.analyzer.bestMove(
                from: game.position,
                forRoll: roll
            )
        }
    }
    
    private func analyzeMoves() {
        guard let pendingAnalyze = pendingAnalyze else { return }
        
        // Doesn't make sense to press analyze twice.
        analyzeButton.enabled = false
        
        // Record the current epoch so we can detect stale analyses.
        let analysisEpoch = pickMoveEpoch
        
        Task { @MainActor in
            let analysis = await pendingAnalyze.value
            guard analysisEpoch == pickMoveEpoch else { return }
            
            guard let analysis = analysis else {
                return self.alertNetworkError(
                    "An Internet connection is required to analyze moves."
                ) {
                    self.fetchAnalysis(forRoll: self.game.diceSum)
                    self.analyzeButton.enabled = true
                }
            }
            
            annotateCheckers(with: analysis)
        }
    }
    
    private func pickBestMove(onMovePicked: GameBoard.OnMovePicked) {
        guard let pendingBestMove = pendingBestMove else { return }
        
        Task { @MainActor in
            let move = await pendingBestMove.value
            guard let move = move else {
                return self.alertNetworkError(
                    "An Internet connection is required to play against the computer."
                ) {
                    self.fetchBestMove(forRoll: self.game.diceSum)
                    self.pickMove()
                }
            }
            
            let viewMove = convertMove(move)
            guard let checker = board.checker(at: viewMove.from) else { return }
            executeMove(checker: checker, viewMove: viewMove)
        }
    }
    
    // MARK: Convert between logical and screen positions
    
    private func convertMove(_ move: Move) -> GameBoard.Move {
        return .init(
            from: indexToPoint(move.from),
            to: indexToPoint(move.to),
            userData: move
        )
    }
    
    private func indexToPoint(_ index: Int) -> CGPoint {
        if index < 0 {
            return positions.position(
                game.currentPlayer,
                waitSlot: game.playerPosition().waitCount - 1
            )
        } else {
            return positions.position(
                game.currentPlayer,
                index: index
            )
        }
    }
}
