//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import Foundation

// Stores the value of a GamePosition
struct PositionValue: Identifiable, Comparable {
    let id: Int32
    let value: Float
    
    static func == (lhs: PositionValue, rhs: PositionValue) -> Bool { lhs.id == rhs.id }
    static func < (lhs: PositionValue, rhs: PositionValue) -> Bool { lhs.id < rhs.id }
}

// Stores all possible game positions.
public final class PositionValues {
    private var values = [PositionValue]()
    
    init(values: consuming [PositionValue]) {
        self.values = values
    }
    
    init(data: borrowing Data) {
        self.values = data.withUnsafeBytes {
            [PositionValue]($0.bindMemory(to: PositionValue.self))
        }
    }
    
    public convenience init?(fileURLWithPath: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: fileURLWithPath)) else {
            return nil
        }
        self.init(data: data)
    }
    
    public subscript(position: GamePosition) -> Float {
        // The index is exhaustive, so we should never see an unknown id.
        return values[values.bsearch(by: \.id, for:  position.id)!].value
    }
    
    public func encode() -> Data { values.withUnsafeBytes { Data($0) } }
}
