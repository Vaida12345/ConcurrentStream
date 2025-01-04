//
//  ConcurrentAsyncSequenceStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


private final class ConcurrentAsyncSequenceStream<Source>: ConcurrentStream where Source: AsyncSequence {
    
    private var iterator: Source.AsyncIterator
    
    fileprivate init(source: consuming Source, of element: Source.Element.Type = Source.Element.self) {
        self.iterator = source.makeAsyncIterator()
    }
    
    fileprivate func next() async throws -> Source.Element? {
        try await iterator.next()
    }
    
    nonisolated var cancel: @Sendable () -> Void {
        // do nothing
        return {}
    }
    
    typealias Failure = any Error
    
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
    public consuming func stream(of Element: Self.Element.Type = Self.Element.self) -> some ConcurrentStream<Self.Element, any Error> {
        ConcurrentAsyncSequenceStream(source: self, of: Self.Element.self)
    }
    
}



// MARK: - New Implementation
@available(macOS 15, iOS 18, *)
private final class ConcurrentAsyncThrowingSequenceStream<Source>: ConcurrentStream where Source: AsyncSequence {
    
    private var iterator: Source.AsyncIterator
    
    fileprivate init(source: consuming Source) {
        self.iterator = source.makeAsyncIterator()
    }
    
    fileprivate func next() async throws(Failure) -> Element? {
        try await iterator.next(isolation: nil)
    }
    
    nonisolated var cancel: @Sendable () -> Void {
        // do nothing
        return {}
    }
    
    fileprivate typealias Element = Source.Element
    
    typealias Failure = Source.AsyncIterator.Failure
    
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
    @available(macOS 15, iOS 18, *)
    public var stream: some ConcurrentStream<Element, Failure> {
        consuming get {
            ConcurrentAsyncThrowingSequenceStream(source: consume self)
        }
    }
    
}

