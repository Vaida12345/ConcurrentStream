//
//  ConcurrentMapStream.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


internal struct ConcurrentMapStream<Element, SourceStream>: ConcurrentStream where Element: Sendable, SourceStream: ConcurrentStream {
    
    let source: SourceStream
    
    let map: (SourceStream.Element) async throws -> Element
    
    func returns<T>(handler: (ResultSequence) async throws -> T) async rethrows -> T {
        try await source.returns { results in
            try await withThrowingTaskGroup(of: (ConcurrentStreamIndex, Element).self) { taskGroup in
                for try await result in results {
                    let index = result.0
                    let element = result.1
                    taskGroup.addTask {
                        let result = try await self.map(element)
                        return (index, result)
                    }
                }
                
                return try await handler(taskGroup)
            }
        }
    }
    
    typealias ResultSequence = ThrowingTaskGroup<(ConcurrentStreamIndex, Element), any Error>
    
}


public struct ConcurrentStreamIndex {
    
    var contents: [Int]
    
    init(contents: [Int]) {
        self.contents = contents
    }
    
}
