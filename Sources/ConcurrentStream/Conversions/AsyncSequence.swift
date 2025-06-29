//
//  ConcurrentAsyncSequenceStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
actor ConcurrentAsyncThrowingSequenceStream<Source>: ConcurrentStream where Source: AsyncSequence, Source.Element: Sendable {
    
    @usableFromInline
    var iterator: Source.AsyncIterator
    
    @usableFromInline
    let cancel: @Sendable () -> Void = {} // do nothing
    
    @inlinable
    init(source: consuming Source) {
        self.iterator = source.makeAsyncIterator()
    }
    
    @inlinable
    func next() async throws(Failure) -> sending Element? {
        var iterator = self.iterator
        let next = try await iterator.next(isolation: self)
        self.iterator = iterator
        return next
    }
    
    @usableFromInline
    typealias Element = Source.Element
    
    @usableFromInline
    typealias Failure = Source.AsyncIterator.Failure
    
}


extension AsyncSequence where Element: Sendable, Self: Sendable {
    
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
    @inlinable
    public var stream: some ConcurrentStream<Element, Failure> {
        consuming get {
            ConcurrentAsyncThrowingSequenceStream(source: consume self)
        }
    }
    
}

