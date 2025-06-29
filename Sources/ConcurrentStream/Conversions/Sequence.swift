//
//  ConcurrentSequenceStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
actor ConcurrentSequenceStream<Source>: ConcurrentStream where Source: Sequence, Source.Element: Sendable {
    
    @usableFromInline
    var iterator: Source.Iterator
    
    @usableFromInline
    let cancel: @Sendable () -> Void = {} // do nothing
    
    @inlinable
    init(source: consuming Source) {
        self.iterator = source.makeIterator()
    }
    
    @inlinable
    func next() -> sending Element? {
        iterator.next()
    }
    
    @usableFromInline
    typealias Element = Source.Element
    
    @usableFromInline
    typealias Failure = Never
    
}


extension Sequence where Element: Sendable, Self: Sendable {
    
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
    @inlinable
    public var stream: some ConcurrentStream<Element, Never> {
        consuming get {
            ConcurrentSequenceStream(source: consume self)
        }
    }
    
}

