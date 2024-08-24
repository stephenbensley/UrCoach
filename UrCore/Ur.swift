//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

// Common definitions
public final class Ur {
    public static let pieceCount = 7
    public static let spaceCount = 14
    public static let diceCount = 4
    
    static func isRosette(space: Int) -> Bool {
        switch space {
        case 3, 7, 13:
            return true
        default:
            return false
        }
    }

    static func isSanctuary(space: Int) -> Bool { space == 7 }
    static func isShared(space: Int) -> Bool { (4..<12).contains(space) }
}
