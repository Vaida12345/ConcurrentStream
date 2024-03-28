//
//  File.swift
//  
//
//  Created by Vaida on 2024/3/28.
//

import Foundation


internal struct ConcurrentFlatMapStream<Element, SourceStream, SegmentOfResult>: ConcurrentStream where Element: Sendable, SourceStream: ConcurrentStream, SegmentOfResult: ConcurrentStream, SegmentOfResult.Element == Element {
    
    let source: SourceStream
    
    let map: (SourceStream.Element) async throws -> SegmentOfResult
    
    func returns<T>(handler: (ResultSequence) async throws -> T) async rethrows -> T {
        try await source.returns { results in
            try await withThrowingTaskGroup(of: (ConcurrentStreamIndex, SegmentOfResult).self) { taskGroup in
                for try await result in results {
                    let index = result.0
                    let element = result.1
                    taskGroup.addTask {
                        let result = try await self.map(element)
                        return (index, result)
                    }
                }
                
                try await withThrowingTaskGroup(of: (ConcurrentStreamIndex, Element).self) { _taskGroup in
                    for try await result in taskGroup {
                        let firstIndex = result.0
                        let element = result.1
                        
                        element.returns { results in
                            <#code#>
                        }
                    }
                }
            }
        }
    }
    
    typealias ResultSequence = AsyncFlatMapSequence<ThrowingTaskGroup<(ConcurrentStreamIndex, SegmentOfResult), any Error>, AsyncSequenceContainer<[(ConcurrentStreamIndex, Element)]>>
    
}
