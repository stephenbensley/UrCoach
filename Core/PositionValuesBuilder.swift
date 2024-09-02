//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import Foundation
import UtiliKit

// Indexes the value of each game position. The class toggles between "read from red, write to
// black" and "read from black, write to red". This allows phased updates of the values and allows
// multiple threads to write to the index without collisions.
final class PositionValuesBuilder {
    private struct Entry: Comparable {
        let id: Int32
        var redValue: Double
        var blackValue: Double
        
        static func == (lhs: Entry, rhs: Entry) -> Bool { lhs.id == rhs.id }
        static func < (lhs: Entry, rhs: Entry) -> Bool { lhs.id < rhs.id }
    }
    
    private enum Color {
        case red
        case black
    }
    
    private var entries = [Entry]()
    private var color = Color.red
    
    // Returns the final values.
    var values: PositionValues {
        // Read from the current color.
        switch color {
        case .red:
            return .init(values: entries.map({ .init(id: $0.id, value: .init($0.redValue  )) }))
        case .black:
            return .init(values: entries.map({ .init(id: $0.id, value: .init($0.blackValue)) }))
        }
    }

    init() {
#if DEBUG
        // It takes a long time to initialize this class in Debug builds, so we cache the initial
        // state to improve debugging and testing times. We don't care if this fails. For Release
        // builds, we'll continue to rebuild everytime to avoid any bugs due to using stale
        // cached state. Solving takes so long in a Debug build that there's no chance anyone
        // would accidentally use the Debug build for the actual solution.
        if load() { return }
#endif
        // Process all possible GamePositions.
        GamePosition.forEach { pos in
            // If it's your turn and the game is over, you've lost, so terminal states have a
            // value of zero. Otherwise, we'll assume it's a tie for now.
            let initVal = pos.terminal ? 0.0 : 0.5
            entries.append(.init(id: pos.id, redValue: initVal, blackValue: initVal))
        }
        // Sort entries so we can use binary search
        entries.sort()
        
#if DEBUG
        save()
#endif
    }
    
    // Returns the index of the position.
    func index(_ position: GamePosition) -> Int {
        guard let index = entries.bsearch(forKey: position.id, extractedBy: \.id) else {
            fatalError("Unrecognized position in PositionValuesBuilder.index")
        }
        return index
    }
    
    subscript(index: Int) -> Double {
        get {
            // Read from the current color.
            switch color {
            case .red:
                return entries[index].redValue
            case .black:
                return entries[index].blackValue
            }
        }
        set {
            // Write to the opposite color.
            switch color {
            case .red:
                entries[index].blackValue = newValue
            case .black:
                entries[index].redValue = newValue
            }
        }
    }
    
    subscript(position: GamePosition) -> Double {
        get { self[index(position)] }
        set { self[index(position)] = newValue }
    }
    
    // Toggles to the other color.
    func toggle() {
        switch color {
        case .red:
            color = .black
        case .black:
            color = .red
        }
    }
    
    // Load from a file.
    func load() -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: "pvb.data")) else {
            return false
        }
        entries = data.withUnsafeBytes { .init($0.bindMemory(to: Entry.self)) }
        return true
    }
    
    // Save to a file.
    func save() {
        let data =  entries.withUnsafeBytes { Data($0) }
        let _ = try? data.write(to: URL(fileURLWithPath: "pvb.data"))
     }
 }
