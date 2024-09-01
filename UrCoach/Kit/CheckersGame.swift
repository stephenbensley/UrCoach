//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UtiliKit/blob/main/LICENSE.
//

import CheckersKit
import SpriteKit

// Signals which view to display.
public enum ViewType {
    case menu
    case game
    case rules
}
// Callback to change the current view
public typealias ChangeView = (ViewType) -> Void

public protocol CheckersGame {
    var name: String { get }
    var description: String { get }
    
    func getScene(size: CGSize, changeView: @escaping ChangeView) -> SKScene
    
    func newGame(white: PlayerType, black: PlayerType) -> Void
    
    func save() -> Void
}

class MockDelegate: CheckersGame {
    var name = "Mock Delegate"
    var description = "This is a Mock Delegate"
    func getScene(size: CGSize, changeView: @escaping ChangeView) -> SKScene { .init() }
    func newGame(white: PlayerType, black: PlayerType) { }
    func save() { }
}
