//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

// Implements PositionAnalyzer by querying node state from a solution database.
final class SolutionDB: PositionAnalyzer {
    private var client: SolutionDBClient
    private var cache = [Int32: SolutionNode]()
    
    init(client: SolutionDBClient) {
        self.client = client
    }
    
    func analyze(position: GamePosition, roll: Int) async throws -> [MoveValue] {
        let moves = position.moves(forRoll: roll)
        
        // Prime the cache with all reachable nodes.
        let childIds = moves.map { position.tryMove(move: $0).0.id }
        try await fetch(childIds)
        
        return moves.map({ move in
            let (nextPosition, nextPlayer) = position.tryMove(move: move)
            let value = cache[nextPosition.id]!.value
            return MoveValue(move: move, value: (nextPlayer ? 1.0 - value : value))
        }).sorted(by: >)
    }
    
    func bestMove(from position: GamePosition, forRoll roll: Int) async throws -> Move? {
        let moves = position.moves(forRoll: roll)
        
        // No need to query the database unless 2 or more moves are possible.
        guard !moves.isEmpty else { return nil }
        guard moves.count > 1 else { return moves[0] }
        
        // Prime the cache.
        let id = position.id
        try await fetch([id])
        
        let node = cache[id]!
        return moves[node.policy[roll - 1]]
    }
    
    // Fetch the specified ids into the cache.
    private func fetch(_ ids: [Int32]) async throws {
        // Remove ids that are already in the cache.
        let missing = ids.filter { !cache.keys.contains($0) }
        
        if missing.count > 1 {
            // For more than one, we do a batch get
            let nodes = try await client.getNodes(ids: missing)
            // Make sure we got what we asked for.
            guard missing.sorted() == nodes.map({ $0.id }).sorted() else {
                throw SolutionDBError.unexpectedResponse
            }
            nodes.forEach { cache[$0.id] = $0 }
        } else if missing.count == 1 {
            // For exactly one, we do a simple get.
            let node = try await client.getNode(id: ids[0])
            // Make sure we got what we asked for.
            guard missing[0] == node.id else {
                throw SolutionDBError.unexpectedResponse
            }
            cache[node.id] = node
        }
    }
}
