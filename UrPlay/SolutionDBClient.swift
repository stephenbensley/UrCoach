//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import Foundation
import UrCore

// Errors thrown by SolutionDBClient
enum SolutionDBError: Error {
    case transportError(Error)
    case serverError(Int)
}

// Game node information stored in the database.
public struct SolutionDBNode: Equatable {
    // GamePosition.id
    let id: Int32
    // Attacker's win probability
    let value: Float
    // Best move for rolls 1...4
    let policy: [Int]
    
    public init(id: Int32, value: Float, policy: [Int]) {
        self.id = id
        self.value = value
        self.policy = policy
    }
}

extension PositionValues {
    public func solutionDbNode(for position: GamePosition) -> SolutionDBNode {
        let id = position.id
        let value = self[position]
        let policy = self.policy(for: position)
        return SolutionDBNode(id: id, value: value, policy: policy)
    }
}

// This is defined as a protocol, so we can mock it.
protocol SolutionDBClient {
    func getNode(id: Int32) async throws -> SolutionDBNode
    func getNodes(ids: [Int32]) async throws -> [SolutionDBNode]
}

// Low-level wrapper around the web API to query the Ur solution stored in AWS.
final class CloudSolutionDBClient: SolutionDBClient {
    func getNode(id: Int32) async throws -> SolutionDBNode {
        let key = DynamoNode.uint32ToDynamoValue(UInt32(bitPattern: id))
        let dynNode = try await Self.getNode(key: key)
        guard let dbNode = dynNode.solutionDBNode else {
            throw SolutionDBError.serverError(422)  // Unprocessable Content
        }
        return dbNode
    }

    func getNodes(ids: [Int32]) async throws -> [SolutionDBNode] {
        let keys = ids.map { DynamoNode.uint32ToDynamoValue(UInt32(bitPattern: $0)) }
        let dynNodes = try await Self.getNodes(keys: keys)
        return try dynNodes.map {
            guard let dbNode = $0.solutionDBNode else {
                throw SolutionDBError.serverError(422)  // Unprocessable Content
            }
            return dbNode
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

final class MockSolutionDBClient: SolutionDBClient {
    private var solution: PositionValues
    
    init(solution: PositionValues) {
        self.solution = solution
    }
    
    func getNode(id: Int32) async throws -> SolutionDBNode {
        let position = GamePosition(id: id)
        let value = solution[position]
        let policy = solution.policy(for: position)
        
        // Swizzle it back and forth to simulate the data conversions.
        return DynamoNode(SolutionDBNode(id: id, value: value, policy: policy)).solutionDBNode!
    }
    
    func getNodes(ids: [Int32]) async throws -> [SolutionDBNode] {
        var result = [SolutionDBNode]()
        for id in ids { try await result.append(getNode(id: id)) }
        return result
    }
}
