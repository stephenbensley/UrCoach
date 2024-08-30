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


public extension GamePalette {
    static let analysisGreen = BoardGameColor(Color(.analysisGreen))
    static let analysisRed   = BoardGameColor(Color(.red))
    static let bottomSheet   = BoardGameColor(Color(.gray))
}

final class GameScene: SKScene {
    // Game coordinates are designed for this size.
    static private let minSize = CGSize(width: 390, height: 750)
    
    // SKNode names
    static private let annotationName = "annotation"
    
    // Global game state
    private var appModel = UrModel.shared
    // Set by the enclosing SwiftUI view to allow this scene to return to the main menu.
    private var changeView: ChangeView? = nil
    
    // Used to map logical board positions to screen coordinates.
    private let positions = BoardPositions()
    
    // These nodes are interacted with frequently, so we cache references to them.
    private let board = GameBoard()
    private let whiteDice = RollingDice(diceCount: Ur.diceCount, orientation: .vertical)
    private let blackDice = RollingDice(diceCount: Ur.diceCount, orientation: .vertical)
    private let analyzeButton = SKButton("Analyze", size: .init(width: 125, height: 45))
    private let menuButton = SKButton("Menu", size: .init(width: 125, height: 45))
    
    // The next roll of the dice. We precompute this, so we can query the analyzer as soon as
    // possible, but we don't want to update the appModel until we've shown this roll to the
    // players.
    private var pendingDice = [Int]()
    private var pendingDiceSum: Int = 0
    // Allowed moves the current player may select from.
    private var allowedMoves = [Move]()
    
    // True if a human is playing solo against the computer.
    private var solo = false
    // Pending SolutionDB queries (if any).
    private var pendingBestMove: Task<Move?, Never>? = nil
    private var pendingAnalyze: Task<[MoveValue]?, Never>? = nil
    // Used to detect stale move analyses. If the user has already picked a move, by the time the
    // analysis completes, then the analysis isn't useful anymore.
    private var pickMoveEpoch = 0
    
    // Helpers for frequently accessed state.
    private var currentType: PlayerType { appModel.playerType[game.currentPlayer.rawValue] }
    private var game: GameModel { appModel.game }
    
    // MARK: Initialization
    
    override init() {
        super.init(size: Self.minSize)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.backgroundColor = GamePalette.background
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
            let pos = positions.position(.white, i)
            board.addTarget(at: pos)
            if !Ur.isShared(space: i) {
                board.addTarget(at: pos.reflectedOverY)
            }
        }
    }
    
    // Invoked when we've been added to a SwiftUI view.
    func addedToView(size: CGSize, changeView: @escaping ChangeView) {
        self.size = Self.minSize.stretchToAspectRatio(size.aspectRatio)
        self.changeView = changeView
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
        
        changeView?(.menu)
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
        // Setup the dice.
        whiteDice.setValues(game.whiteDice)
        blackDice.setValues(game.blackDice)
        pendingDice = .init()
        pendingDiceSum = 0
        
        // Place the checkers on the board.
        board.clear()
        placeCheckers(player: .white, pieces: game.playerPosition(for: .white))
        placeCheckers(player: .black, pieces: game.playerPosition(for: .black))
        
        // Recompute properties in case something has changed.
        board.inputEnabled = true
        allowedMoves = game.moves(forRoll: game.diceSum)
        solo = appModel.playerType[0] == .computer || appModel.playerType[1] == .computer
        pickMoveEpoch += 1
        
        // Place the buttons based on whether we're in solo mode.
        if solo {
            analyzeButton.enabled = false
            if analyzeButton.parent == nil {
                addChild(analyzeButton)
            }
            menuButton.position = .init(x: -80.0, y: -310.0)
        } else {
            analyzeButton.removeFromParent()
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
            let pos = positions.position(player, i - BoardPositions.indexOffset)
            board.addChecker(for: player, at: pos)
        }
        
        for i in 0..<Ur.spaceCount where pieces.occupies(space: i) {
            let pos = positions.position(player, i)
            board.addChecker(for: player, at: pos)
        }
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
        pendingDice = GameModel.rollDice()
        pendingDiceSum = pendingDice.reduce(0, +)
        allowedMoves = game.moves(forRoll: pendingDiceSum)
        
        let dice: RollingDice
        switch game.currentPlayer {
        case .white:
            dice = whiteDice
        case .black:
            dice = blackDice
        }
        
        // Initiate network I/O before animating the dice. This buys us some extra time for
        // network latency.
        switch currentType {
        case .human:
            fetchAnalysis(forRoll: pendingDiceSum)
            dice.rollOnTap(newValues: pendingDice, completion: rollComplete)
        case .computer:
            fetchBestMove(forRoll: pendingDiceSum)
            dice.roll(newValues: pendingDice, completion: rollComplete)
        }
    }
    
    private func rollComplete() {
        game.rollDice(dice: pendingDice)
        if allowedMoves.isEmpty {
            displayNoMove()
        } else {
            pickMove()
        }
    }
    
    private func displayNoMove() {
        let alert = AutoAlert("\(game.currentPlayer) has no move")
        addChild(alert)
        game.makeMove(move: nil)
        alert.display(forDuration: 1.5, completion: rollDice)
    }
    
    private func pickMove() {
        switch currentType {
        case .human:
            if solo { analyzeButton.enabled = true }
            board.pickMove(
                for: game.currentPlayer,
                moves: allowedMoves.map(convertMove),
                onMovePicked: executeMove
            )
        case .computer:
            pickBestMove(
                onMovePicked: executeMove
            )
        }
    }
    
    private func executeMove(checker: Checker, viewMove: GameBoard.Move) {
        guard let modelMove = viewMove.userData as? Move else { return }
        
        removeAnnotations()
        pickMoveEpoch += 1

        // Build the animation before updating the game model.
        let actions = buildMoveAnimation(checker: checker, viewMove: viewMove)

        game.makeMove(move: modelMove)

        let nextState: () -> Void
        if game.isOver {
            nextState = displayGameOutcome
        } else if Ur.isRosette(space: modelMove.to) {
            nextState = displayRollAgain
        } else {
            nextState = rollDice
        }

        checker.run(SKAction.sequence(actions), completion: nextState)
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
    
    func buildMoveAnimation(checker: Checker, viewMove: GameBoard.Move) -> [SKAction] {
        guard let modelMove = viewMove.userData as? Move else { return .init() }
        
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
        
        return actions
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
    
    
    // MARK: Annotations
    
    private func annotateCheckers(with analysis: [MoveValue]) {
        for (i, move) in analysis.enumerated() {
            annotateChecker(at: move.move.from, with: move.value, isBest: (i == 0))
        }
    }
    
    private func annotateChecker(at index: Int, with winProb: Float, isBest: Bool) {
        guard let checker = board.checker(at: indexToPoint(index)) else { return }
        
        let label = SKLabelNode()
        label.fontColor = isBest ?  UIColor(Color(.analysisGreen)): .red
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
        guard solo else { return }
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
        analyzeButton.enabled = false
        guard let pendingAnalyze = pendingAnalyze else { return }
        let epoch = pickMoveEpoch
        
        Task { @MainActor in
            let analysis = await pendingAnalyze.value
            guard epoch == pickMoveEpoch else { return }
            
            guard let analysis = analysis else {
                return self.alertNetworkError(
                    "An Internet connection is required to analyze moves."
                ) {
                    self.fetchAnalysis(forRoll: self.game.diceSum)
                    self.analyzeButton.enabled = true
                }
            }
            
            annotateCheckers(with: analysis)
            self.pendingAnalyze = nil
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
        let shifted: Int
        if index < 0 {
            shifted = index + game.playerPosition().waitCount - BoardPositions.indexOffset
        } else {
            shifted = index
        }
        return positions.position(game.currentPlayer, shifted)
    }
}
