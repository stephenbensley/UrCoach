//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import Foundation
import UrCore

// Exports the Ur solution data as a series of JSON files suitable for import to DynamoDB.
@main
final class DynamoDbFileGenerator {
    // The solution being exported.
    private let solution: PositionValues
    // Files for export. The JSON data is ~10GB, all of which needs to be uploaded to Amazon S3.
    // So it's helpful to split it across multiple files in case of upload failures.
    private var files = [BufferedTextFile]()
    
    init?(solution: PositionValues, fileCount: Int) {
        self.solution = solution
        
        for i in 0..<fileCount {
            let fileName = String(format: "urnodes%02d.json", i)
            guard let file = BufferedTextFile(forWritingAtPath: fileName) else { return nil }
            files.append(file)
        }
    }
    
    func generate() throws {
        var count = 0
        try GamePosition.forEach { pos in
            // Round-robin the positions across the export files.
            try files[count % files.count].writeLine(encodePosition(pos))
            count += 1
        }
        try files.forEach { try $0.flush() }
    }
    
    // Converts a game position into DynamoDb JSON.
    private func encodePosition(_ position: GamePosition) -> String {
        let dynNode = DynamoNode(solution.solutionDbNode(for: position))
        return """
               {"Item":{"I":{"S":"\(dynNode.I)"},"V":{"S":"\(dynNode.V)"},"P":{"S":"\(dynNode.P)"}}}
               """
    }
    
    static func main() {
         guard let solution = PositionValues(fileURLWithPath: "urSolution.data") else {
            print("Unable to read urSolution.data.")
            return
        }
        guard let gen = DynamoDbFileGenerator(solution: solution, fileCount: 20) else {
            print("Unable to open output files for writing.")
            return
        }
        do {
            try gen.generate()
        } catch {
            print("Error occurred during file generation.")
            return
        }
    }
}
