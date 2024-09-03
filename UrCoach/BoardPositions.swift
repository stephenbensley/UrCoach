//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import CoreGraphics
import CheckersKit

// Maps logical game positions to their (x, y) coordinates on the screen.
final class BoardPositions {
    // Various constants for mapping board positions. These depend on the exact layout of the
    // gameboard image.
    private static let waitingOrigin = CGPoint(x: -115.0, y: -202.5)
    private static let waitingOffset = CGFloat(30.0)
    private static let inPlayOrigin  = CGPoint(x: 0.0, y: -27.5)
    private static let inPlayOffset  = CGFloat(55.0)

    // Zero square has Ur.pieceCount waiting positions and the 'just before entry' square
    // ahead of it in the positions array.
    private static let originOffset = Ur.pieceCount + 1
    // Cached position values for each player.
    private var positions = [[CGPoint]](repeating: .init(), count: 2)
    
    init() {
        for i in 0..<Ur.pieceCount {
            positions[0].append(Self.whiteWaitingPosition(i))
        }
        for i in -1...Ur.spaceCount {
            positions[0].append(Self.whiteInPlayPosition(i))
        }
        positions[1] = positions[0].reflectedOverY
    }
    
    // Returns the position based on index, where zero is the entry square.
    func position(_ player: PlayerColor,  index: Int) -> CGPoint {
        // Zero square has Ur.pieceCount waiting positions and the 'just before entry' square
        // ahead of it in the positions array.
        positions[player.rawValue][index + Self.originOffset]
    }
    
    // Returns the position based on wait slot, where zero is the last slot to enter play.
    func position(_ player: PlayerColor, waitSlot: Int) -> CGPoint {
        positions[player.rawValue][waitSlot]
    }

    // Location of white's checkers waiting to enter specified by index. Zero is the checker at
    // the bottom, i.e., the last checker to enter.
    static func whiteWaitingPosition(_ index: Int) -> CGPoint {
        .init(
            x: waitingOrigin.x + (index % 2 == 1 ? -waitingOffset : 0),
            y: waitingOrigin.y + waitingOffset * CGFloat(index)
        )
    }
    
    // Location of white's squares on the Ur board specified by index. Zero is the entry square.
    // -1 is the offboard location just before entry; Ur.spaceCount is the offboard location right
    // after exit.
    static func whiteInPlayPosition(_ index: Int) -> CGPoint {
        switch index {
        case -1...3:
            return inPlayPosition(.init(x: -1, y: -index))
        case 4...11:
            return inPlayPosition(.init(x: 0, y: index - 7))
        case 12...14:
            return inPlayPosition(.init(x: -1, y: 16 - index))
        default:
            return .init()
        }
    }
    
    // Position of spaces on the Ur board specified by space coordinates. The origin is the middle
    // rosette, and coordinates are specified by space count, e.g., the space directly above the
    // rosette is (0, 1).
    static func inPlayPosition(_ coordinates: CGPoint) -> CGPoint {
        .init(
            x: inPlayOrigin.x + inPlayOffset * coordinates.x,
            y: inPlayOrigin.y + inPlayOffset * coordinates.y
        )
    }
}
