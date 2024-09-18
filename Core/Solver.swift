//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import Foundation
import UtiliKit

// Stores the game graph flattened into an array that's processed linearly. This reduces memory
// usage and improves data locality.
final class GameGraph {
    // Indices of the graph nodes in PositionValueBuilder. The index is negated to indicate
    // that the move doesn't cause a change of player.
    private var indices = [Int32]()
    // Next index to be read.
    private var cursor = 0
    
    // Returns true if the end has been reached.
    var end: Bool { cursor == indices.count }
    
    // Append an index when building the graph.
    func append(_ index: Int, nextPlayer: Bool = true) {
        indices.append(Int32(nextPlayer ? index : -index))
    }
    
    // Get the next index when processing the graph.
    func next() -> (Int, Bool) {
        let index = Int(indices[cursor])
        cursor += 1
        return (index > 0) ? (index, true) : (-index, false)
    }
    
    // Allow the graph to be reused.
    func removeAll() {
        indices.removeAll()
        cursor = 0
    }
    
    // Reset for another processing pass.
    func reset() { cursor = 0}
}

// Solves a portion of the game graph. The class exposes a buildGraph/update API. Solver always
// invokes these from within a single Task.
fileprivate final class SolverWorker: @unchecked Sendable {
    // Probabilty of the various dice rolls.
    private static let pRoll = [0.0625, 0.25, 0.375, 0.25, 0.0625]
    // Current state of the solution
    private let builder: PositionValuesBuilder
    // Game graph being solved. The Ur graph is broken into metastates based on safe counts. The
    // metastates are then broken into chunks for each worker. This is the graph for the current
    // chunk being solved, not the overall game of Ur.
    private let graph = GameGraph()
    
    init(builder: PositionValuesBuilder) {
        self.builder = builder
    }
    
    // Builds the game graph for the given positions.
    func buildGraph<T: Collection>(for positions: T) where T.Element == GamePosition {
        graph.removeAll()
        positions.forEach(append)
    }
    
    // Appends a node to the game graph.
    private func append(_ position: GamePosition) {
        // First store the index of this node.
        let index = builder.index(position)
        graph.append(index)
        
        // Compute the index for the cases where we have no move. This will always be used at
        // least once since a roll of zero never has a move.
        let noMove = builder.index(position.reversed)
        
        // Add the moves for each roll.
        for roll in 0...4 {
            let moves = position.moves(forRoll: roll)
            if moves.isEmpty {
                graph.append(noMove)
            } else {
                for move in moves {
                    let (nextPos, nextPlayer) = position.tryMove(move: move)
                    graph.append(builder.index(nextPos), nextPlayer: nextPlayer)
                }
            }
            
            // Add a null terminator.
            graph.append(0)
        }
    }
    
    // Updates all nodes in the graph and returns the maximum change for any node.
    func update() -> Double {
        graph.reset()
        var maxDelta = 0.0
        while !graph.end {
            let delta = updateNode()
            maxDelta = max(maxDelta, delta)
        }
        return maxDelta
    }
    
    // Updates the next node in the graph and returns how much its value changed.
    private func updateNode() -> Double {
        // Save the index of the position we're processing and the starting value.
        let (index, _) = graph.next()
        let before = builder[index]
        
        // Value of this node is the value of all the rolls weighted by their probability.
        let value = Self.pRoll.reduce(0.0) { $0 + $1 * nextRollValue() }
        
        // Store the result ...
        builder[index] = value
        // .. and return the delta.
        return abs(value - before)
    }
    
    // Returns the expected value of the optimal move for a given roll of the dice.
    private func nextRollValue() -> Double {
        // Values represent win probability, so value can never be negative.
        var maxValue = 0.0
        // There is guaranteed to be at least one child node (e.g., no move)
        var (index, nextPlayer) = graph.next()
        
        // Process children until we hit the null terminator.
        repeat {
            var value = builder[index]
            // The other player's win is our loss
            if nextPlayer { value = 1.0 - value }
            // We only care about the value of the optimal move.
            maxValue = max(maxValue, value)
            // Get the next child node.
            (index, nextPlayer) = graph.next()
        } while index != 0
        
        return maxValue
    }
}

// Solves the game of Ur.
final class Solver: Sendable {
    // Used to report progress towards the solution.
    enum Progress {
        case buildingGraph(state: SafeCounts)
        case optimzing(iteration: Int, delta: Double)
    }
    typealias ReportProgress = @MainActor (Progress) -> Void
    
    // Ultimately, we'll store the values as a Float which has a 23-bit mantissa. In the upper half
    // of our range (0.5..<1.0), the exponent is -1, so we have a precision of 2^-24. We solve for
    // one extra bit to minimize rounding errors. In reality, even this is overkill. Due to the
    // randomness of Ur, it would take a tremendous number of iterations to dectect an error of
    // even 10^-5.
    static let threshold = pow(2.0, -25.0)
    // Current state of the solution
    private let builder: PositionValuesBuilder
    // Closure used to report progress towards the solution
    private let reportProgress: ReportProgress
    // Workers that solve chunks of the graph.
    private let workers: [SolverWorker]
    
    private init(builder: PositionValuesBuilder, reportProgress: @escaping ReportProgress) {
        self.builder = builder
        self.reportProgress = reportProgress
        let workerCount = ProcessInfo.processInfo.performanceProcessorCount
        self.workers = (0..<workerCount).map { _ in .init(builder: builder) }
    }
    
    // Solve the game of Ur.
    private func solve() async {
        // For retrograde analysis, we need to start with (7, 7) and work back to (0, 0)
        let states = SafeCounts.all.sorted(by: >)
        for state in states {
            await buildGraph(for: state)
            await optimize()
        }
    }
    
    // Builds the game graph for the given metastate.
    private func buildGraph(for state: SafeCounts) async {
        await reportProgress(.buildingGraph(state: state))
        
        // Get all the GamePositions for this state
        let positions = state.all
        
        // Then divide these positions among the workers.
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<workers.count {
                // Compute the range for this worker.
                let start = (i * positions.count) / workers.count
                let end = ((i + 1) * positions.count) / workers.count
                
                // Add a task for the worker.
                group.addTask(priority: .low) {
                    self.workers[i].buildGraph(for: positions[start..<end])
                }
            }
            await group.waitForAll()
        }
    }
    
    // Optimize the graph.
    private func optimize() async {
        var delta = 0.0
        var iteration = 0
        repeat {
            delta = await update()
            iteration += 1
            await reportProgress(.optimzing(iteration: iteration, delta: delta))
        } while delta > Self.threshold
    }
    
    // Updates all nodes in the graph and returns the maximum change for any node.
    private func update() async -> Double {
        let delta = await withTaskGroup(of: Double.self) { group in
            for worker in workers {
                group.addTask(priority: .low) {
                    worker.update()
                }
            }
            return await group.reduce(0.0) { max($0, $1) }
        }
        builder.toggle()
        return delta
    }
    
    static func solve(reportProgress: @escaping ReportProgress) async -> PositionValues {
        let builder = PositionValuesBuilder()
        await Solver(builder: builder, reportProgress: reportProgress).solve()
        return builder.values
    }
}
