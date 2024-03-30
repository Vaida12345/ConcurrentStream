//
//  ConcurrentSequenceStream.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


private final class ConcurrentSequenceStream<Source>: ConcurrentStream where Source: Sequence {
    
    private var iterator: Source.Iterator
    
    fileprivate init(source: Source) {
        self.iterator = source.makeIterator()
    }
    
    fileprivate func next() async throws -> Element? {
        iterator.next()
    }
    
    fileprivate func cancel() {
        // do nothing
    }
    
    fileprivate typealias Element = Source.Element
    
}


extension Sequence {
    
    /// Creates a stream from a sequence.
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
        ConcurrentSequenceStream(source: self)
    }
    
}

