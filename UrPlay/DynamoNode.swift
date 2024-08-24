//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

// Representation of a game node in DynamoDB.
public struct DynamoNode: Codable {
    // Encoded id
    public let I: String
    // Encoded value
    public let V: String
    // Encoded policy
    public let P: String
    
    init(I: String, V: String, P: String) {
        self.I = I
        self.V = V
        self.P = P
    }
    
    public init(_ dbNode: SolutionDBNode) {
        let I = Self.uint32ToDynamoValue(UInt32(bitPattern: dbNode.id))
        
        let V = Self.floatToDynamoValue(dbNode.value)
        
        var packedPolicy: UInt16 = 0
        for p in dbNode.policy {
            packedPolicy <<= 4
            packedPolicy |= UInt16(p)
        }
        let P = Self.uint16ToDynamoValue(packedPolicy)
        
        self.init(I: I, V: V, P: P)
    }
    
    var solutionDBNode: SolutionDBNode? {
        guard let asUInt32 = Self.dynamoValueToUInt32(I) else { return nil }
        let id = Int32(bitPattern: asUInt32)
        
        guard let value = Self.dynamoValueToFloat(V) else { return nil }
        
        guard var packedPolicy = Self.dynamoValueToUInt16(P) else { return nil }
        var policy = [Int]()
        for _ in 0..<4 {
            policy.append(Int(packedPolicy & 0xf))
            packedPolicy >>= 4
        }
        policy.reverse()
        
        return .init(id: id, value: value, policy: policy)

    }
    
    static func floatToDynamoValue(_ value: Float) -> String {
        let asUInt32 = withUnsafeBytes(of: value) {
            $0.bindMemory(to: UInt32.self).baseAddress!.pointee
        }
        return uint32ToDynamoValue(asUInt32)
    }
    
    static func uint16ToDynamoValue(_ value: UInt16) -> String {
        String(format: "%04X", value)
    }
    
    static func uint32ToDynamoValue(_ value: UInt32) -> String {
        String(format: "%08X", value)
    }
    
    static func dynamoValueToFloat(_ value: String) -> Float? {
        guard let asUInt32 = dynamoValueToUInt32(value) else {
            return nil
        }
        return withUnsafeBytes(of: asUInt32) {
            $0.bindMemory(to: Float.self).baseAddress?.pointee
        }
    }
    
    static func dynamoValueToUInt16(_ value: String) -> UInt16? {
        guard value.count == MemoryLayout<UInt16>.size * 2 else {
            return nil
        }
        return UInt16(value, radix: 16)
    }
    
    static func dynamoValueToUInt32(_ value: String) -> UInt32? {
        guard value.count == MemoryLayout<UInt32>.size * 2 else {
            return nil
        }
        return UInt32(value, radix: 16)
    }
}
