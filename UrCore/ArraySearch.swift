//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

// Extends array to support binary search
extension Array where Element: Comparable {
    
    // Look for a match of the element.
    public func bsearch(for element: Self.Element) -> Self.Index? {
        bsearch(by: \.self, for: element)
    }
    
    // Look for a match of a property of the element.
    public func bsearch<T>(
        by keyPath: KeyPath<Element, T>,
        for value: T
    ) -> Self.Index? where T: Comparable {
        var lo: Self.Index = 0
        var hi: Self.Index = self.count - 1
        
        while lo <= hi {
            let mid: Self.Index = (lo + hi) / 2
            if self[mid][keyPath: keyPath] == value {
                return mid
            } else if self[mid][keyPath: keyPath] < value {
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return nil
    }
}
