//
//  AsyncIterator.swift
//  ConcurrentStream
//
//  Created by Vaida on 2025-06-11.
//


@usableFromInline
actor ConcurrentAsyncThrowingIteratorStream<Source>: ConcurrentStream where Source: AsyncIteratorProtocol, Source.Element: Sendable {
    
    @usableFromInline
    var iterator: Source
    
    @inlinable
    init(source: Source) {
        self.iterator = source
    }
    
    @inlinable
    func next() async throws(Failure) -> sending Element? {
        var iterator = self.iterator
        let next = try await iterator.next(isolation: self)
        self.iterator = iterator
        return next
    }
    
    @inlinable
    nonisolated var cancel: @Sendable () -> Void {
        // do nothing
        return {}
    }
    
    @usableFromInline
    typealias Element = Source.Element
    
    @usableFromInline
    typealias Failure = Source.Failure
    
}


extension AsyncIteratorProtocol where Element: Sendable, Self: Sendable {
    
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
            ConcurrentAsyncThrowingIteratorStream(source: self)
        }
    }
    
}

