//
//  ConcurrentAsyncSequenceStream.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


private final class ConcurrentAsyncSequenceStream<Source>: ConcurrentStream where Source: AsyncSequence {
    
    private var iterator: Source.AsyncIterator
    
    fileprivate init(source: Source) {
        self.iterator = source.makeAsyncIterator()
    }
    
    fileprivate func next() async throws -> Element? {
        try await iterator.next()
    }
    
    fileprivate func cancel() {
        // do nothing
    }
    
    fileprivate typealias Element = Source.Element
    
}


extension AsyncSequence {
    
    /// Creates a stream from an `AsyncSequence`.
    ///
    /// > Example:
    /// >
    /// > Create a stream of 1 through 10.
    /// > ```swift
    /// > (1...10).stream
    /// >```
    ///
    /// - Returns: The iterator for the sequence is created before returning.
    ///
    /// - Complexity: O(*1*).
    public var stream: some ConcurrentStream<Element> {
        ConcurrentAsyncSequenceStream(source: self)
    }
    
}

