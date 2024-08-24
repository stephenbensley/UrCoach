//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

// Stores the safeCounts for a game position without differentiating between attacker and defender.
// This is useful for defining metastates in the game graph. Since safeCounts can only increase, we
// can superimpose a tree of metastates based on safeCounts. Thus, the graph can be partitioned
// and solved in chunks. We don't differentiate between attacker and defender since in any meta-
// state, we can trivially reverse attacker & defender by rolling a zero.
struct SafeCounts: Comparable {
    private(set) var hi: Int
    private(set) var lo: Int
    
    init(hi: Int, lo: Int) {
        assert(hi >= lo)
        self.hi = hi
        self.lo = lo
    }
    
    // True if the attacker and defender have the same safeCount
    var symmetric: Bool { hi == lo }
    
    // Total safeCount of both attacker and defender
    var total: Int { hi + lo}
    
    // Returns all SafeCounts
    static var all: [SafeCounts] {
        (0...Ur.pieceCount).flatMap { hi in
            (0...hi).map { lo in
                SafeCounts(hi: hi, lo: lo)
            }
        }
    }
    
    // Returns all GamePositions with matching safeCounts
    var all: [GamePosition] {
        var result = [GamePosition]()
        let allHi = Self.allPlayerPositions(hi)
        let allLo = symmetric ? allHi : Self.allPlayerPositions(lo)
        for attacker in allHi {
            for defender in allLo where !defender.intersects(with: attacker) {
                let pos = GamePosition(attacker: attacker, defender: defender)
                result.append(pos)
                if !symmetric {
                    result.append(pos.reversed)
                }
            }
        }
        return result
    }
    
    private static func allPlayerPositions(_ safeCount: Int) -> [PlayerPosition] {
        PlayerPosition.all.filter { ($0.safeCount == safeCount) && !$0.terminal }
    }
    
    static func < (lhs: SafeCounts, rhs: SafeCounts) -> Bool {
        // We order first by total count since total count must always increase. This ensures
        // that we never progress backwards during the game.
        if lhs.total != rhs.total {
            return lhs.total < rhs.total
        } else {
            return lhs.hi < rhs.hi
        }
    }
}
