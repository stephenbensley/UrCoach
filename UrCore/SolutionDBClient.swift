//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import Foundation

// Game node information stored in the database.
struct SolutionNode: Comparable, Hashable {
    // GamePosition.id
    let id: Int32
    // Attacker's win probability
    let value: Float
    // Best move for rolls 1...4
    let policy: [Int]
    
    init(id: Int32, value: Float, policy: [Int]) {
        self.id = id
        self.value = value
        self.policy = policy
    }
    
    static func == (lhs: SolutionNode, rhs: SolutionNode) -> Bool { lhs.id == rhs.id }
    static func < (lhs: SolutionNode, rhs: SolutionNode) -> Bool { lhs.id < rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// Extend PositionValues to generate SolutionNodes.
extension PositionValues {
    func solutionNode(for position: GamePosition) -> SolutionNode {
        let id = position.id
        let value = self[position]
        let policy = self.policy(for: position)
        return SolutionNode(id: id, value: value, policy: policy)
    }
}

// Errors thrown by SolutionDBClient
enum SolutionDBError: Error {
    case transportError(Error)
    case serverError(Int)
    case unexpectedResponse
}

// This is defined as a protocol, so we can mock it.
protocol SolutionDBClient {
    func getNode(id: Int32) async throws -> SolutionNode
    func getNodes(ids: [Int32]) async throws -> [SolutionNode]
}

// Low-level wrapper around the web API to query the Ur solution stored in AWS.
final class CloudDBClient: SolutionDBClient {
    func getNode(id: Int32) async throws -> SolutionNode {
        let key = DynamoNode.uint32ToDynamoValue(UInt32(bitPattern: id))
        let dynNode = try await Self.getNode(key: key)
        guard let node = dynNode.solutionNode else {
            throw SolutionDBError.serverError(422)  // Unprocessable Content
        }
        return node
    }
    
    func getNodes(ids: [Int32]) async throws -> [SolutionNode] {
        let keys = ids.map { DynamoNode.uint32ToDynamoValue(UInt32(bitPattern: $0)) }
        let dynNodes = try await Self.getNodes(keys: keys)
        return try dynNodes.map {
            guard let node = $0.solutionNode else {
                throw SolutionDBError.serverError(422)  // Unprocessable Content
            }
            return node
        }
    }
    
    // Retrieve a single DynamoNode.
    private static func getNode(key: String) async throws -> DynamoNode {
        // Build the URL
        let urlString = AWSConfig.resourceUrl + "/" + key
        // Retrieve the data
        let data = try await getData(urlString: urlString)
        // Decode into a DynamoNode
        return try JSONDecoder().decode(DynamoNode.self, from: data)
    }
    
    // Retrieve a batch of nodes.
    private static func getNodes(keys: [String]) async throws -> [DynamoNode] {
        // Build the URL
        let urlString = AWSConfig.resourceUrl + "?" + keys.map({ key in
            "id=\(key)"
        }).joined(separator: "&")
        // Retrieve the data
        let data = try await getData(urlString: urlString)
        // Decode into a DynamoNode array
        return try JSONDecoder().decode([DynamoNode].self, from: data)
    }
    
    // Retrieves the Data associated with an URL.
    private static func getData(urlString: String) async throws -> Data {
        // Convert to an URL object. Caller is trusted, so we'll assume this succeeds.
        let url = URL(string: urlString)!
        
        // Set the API key in the header.
        var request = URLRequest(url: url)
        request.setValue(AWSConfig.apiKey, forHTTPHeaderField: "x-api-Key")
        
        // Get the data.
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Whenever you make an HTTP request, the URLResponse object you get back is actually an
        // instance of the HTTPURLResponse class.
        let httpResponse = response as! HTTPURLResponse
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SolutionDBError.serverError(httpResponse.statusCode)
        }
        return data
    }
}

// Mocks SolutionDBClient by querying the local PositionValues instead of the web service.
final class MockDBClient: SolutionDBClient {
    private var solution: PositionValues
    
    init(solution: PositionValues) {
        self.solution = solution
    }
    
    func getNode(id: Int32) async throws -> SolutionNode {
        let node = solution.solutionNode(for: GamePosition(id: id))
        // Swizzle it back and forth to simulate the data conversions.
        return DynamoNode(node).solutionNode!
    }
    
    func getNodes(ids: [Int32]) async throws -> [SolutionNode] {
        var result = [SolutionNode]()
        for id in ids { try await result.append(getNode(id: id)) }
        return result
    }
}

final class FaultyDBClient: SolutionDBClient {
    private var client = CloudDBClient()
    private var errorRate = 0
    private var extraLatency = 0.0
    
    init(errorRate: Int = 0, extraLatency: Double = 0.0) {
        self.errorRate = errorRate
        self.extraLatency = extraLatency
    }
    
    func getNode(id: Int32) async throws -> SolutionNode {
        try await injectFaults()
        return try await client.getNode(id: id)
    }
    
    func getNodes(ids: [Int32]) async throws -> [SolutionNode] {
        try await injectFaults()
        return try await client.getNodes(ids: ids)
    }
    
    private func injectFaults() async throws {
        if errorRate > 0 {
            if Int.random(in: 1...errorRate) == errorRate {
                try? await Task.sleep(for: .seconds(3.0))
                throw SolutionDBError.unexpectedResponse
            }
        }
        
        if extraLatency > 0.0 {
            try? await Task.sleep(for: .seconds(extraLatency))
        }
    }
}
