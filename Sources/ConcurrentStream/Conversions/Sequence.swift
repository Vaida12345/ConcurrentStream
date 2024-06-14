//
//  ConcurrentSequenceStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


private final class ConcurrentSequenceStream<Source>: ConcurrentStream where Source: Sequence {
    
    private var iterator: Source.Iterator
    
    fileprivate init(source: consuming Source) {
        self.iterator = source.makeIterator()
    }
    
    fileprivate func next() -> Element? {
        iterator.next()
    }
    
    nonisolated var cancel: @Sendable () -> Void {
        // do nothing
        return {}
    }
    
    fileprivate typealias Element = Source.Element
    
    typealias Failure = Never
    
}


extension Sequence {
    
    /// Creates a stream from a `Sequence`.
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
    ///
    /// ## Topics
    /// ### See Also
    /// - ``_Concurrency/AsyncSequence/stream``
    /// - ``Foundation/NSEnumerator/stream(of:)``
    public var stream: some ConcurrentStream<Element, Never> {
        consuming get {
            ConcurrentSequenceStream(source: consume self)
        }
    }
    
}

