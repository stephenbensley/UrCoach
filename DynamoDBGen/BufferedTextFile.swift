//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import Foundation

// Uses a large output buffer to accelerate incrementally writing a large text file.
final class BufferedTextFile {
    static let bufferSize = 64 * 1024
    static let newLine = Character("\n").asciiValue!
    
    private var handle: FileHandle
    private var buffer = [UInt8]()
    
    init?(forWritingAtPath path: String) {
        guard FileManager.default.createFile(atPath: path, contents: nil, attributes: nil) else {
            return nil
        }
        guard let handle = FileHandle(forWritingAtPath: path) else {
            return nil
        }
        self.handle = handle
    }
    
    deinit { try? flush() }
    
    func writeLine(_ s: borrowing String) throws {
        buffer.append(contentsOf: s.utf8)
        buffer.append(Self.newLine)
        if buffer.count >= Self.bufferSize {
            try flush()
        }
    }
    
    func flush() throws {
        try handle.write(contentsOf: buffer)
        buffer.removeAll(keepingCapacity: true)
    }
}
