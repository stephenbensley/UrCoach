//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import CoreGraphics
import CheckersKit

enum BoardIndex {
    case waiting(Int)
    case inPlay(Int)
}

final class BoardLocations {
    private static let waitingOrigin = CGPoint(x: -115.0, y: -202.5)
    private static let waitingOffset = CGFloat(30.0)
    private static let inPlayOrigin = CGPoint(x: 0.0, y: -27.5)
    private static let inPlayOffset = CGFloat(55.0)
    
    private struct Key: Hashable {
        let player: PlayerColor
        let position: CGPoint
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(player.rawValue)
            hasher.combine(position.x)
            hasher.combine(position.y)
        }
    }
    
    private var byPos = [Key: BoardIndex]()
    
    init() {
        for i in -1...14 {
            let idx = BoardIndex.inPlay(i)
            byPos[.init(player: .white, position: position(player: .white, index: idx))] = idx
            byPos[.init(player: .black, position: position(player: .black, index: idx))] = idx
        }
        for i in 0..<7 {
            let idx = BoardIndex.waiting(i)
            byPos[.init(player: .white, position: position(player: .white, index: idx))] = idx
            byPos[.init(player: .black, position: position(player: .black, index: idx))] = idx
        }
    }
    
    func index(player: PlayerColor, position: CGPoint) -> BoardIndex? {
        byPos[.init(player: player, position: position)]
    }

    func position(player: PlayerColor, index: BoardIndex) -> CGPoint {
        let position: CGPoint
        switch index {
        case .waiting(let index):
            position = Self.whiteWaitingPosition(index)
        case .inPlay(let index):
            position = Self.whiteInPlayPosition(index)
        }
        switch player {
        case .white:
            return position
        case .black:
            return position.reflectedOverY
        }
    }
    
    static func whiteWaitingPosition(_ index: Int) -> CGPoint {
        .init(
            x: waitingOrigin.x + (index % 2 == 1 ? -waitingOffset : 0),
            y: waitingOrigin.y + waitingOffset * CGFloat(index)
        )
    }
    
    static func whiteInPlayPosition(_ index: Int) -> CGPoint {
        switch index {
        case -1...3:
            return inPlayPosition(space: (-1, -index))
        case 4...11:
            return inPlayPosition(space: (0, index - 7))
        case 12...14:
            return inPlayPosition(space: (-1, 16 - index))
        default:
            return .init()
        }
    }
    
    static func inPlayPosition(space: (Int, Int)) -> CGPoint {
        return .init(
            x: inPlayOrigin.x + inPlayOffset * CGFloat(space.0),
            y: inPlayOrigin.y + inPlayOffset * CGFloat(space.1)
        )
    }
}
