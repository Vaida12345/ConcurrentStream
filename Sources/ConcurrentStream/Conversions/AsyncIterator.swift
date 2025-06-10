//
//  AsyncIterator.swift
//  ConcurrentStream
//
//  Created by Vaida on 2025-06-11.
//

private final class ConcurrentAsyncIteratorStream<Source>: ConcurrentStream where Source: AsyncIteratorProtocol {
    
    private var iterator: Source
    
    fileprivate init(source: consuming Source, of element: Source.Element.Type = Source.Element.self) {
        self.iterator = source
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


extension AsyncIteratorProtocol {
    
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
        ConcurrentAsyncIteratorStream(source: self, of: Self.Element.self)
    }
    
}



// MARK: - New Implementation
@available(macOS 15, iOS 18, *)
private final class ConcurrentAsyncThrowingIteratorStream<Source>: ConcurrentStream where Source: AsyncIteratorProtocol {
    
    private var iterator: Source
    
    fileprivate init(source: consuming Source) {
        self.iterator = source
    }
    
    fileprivate func next() async throws(Failure) -> Element? {
        try await iterator.next(isolation: nil)
    }
    
    nonisolated var cancel: @Sendable () -> Void {
        // do nothing
        return {}
    }
    
    fileprivate typealias Element = Source.Element
    
    typealias Failure = Source.Failure
    
}


extension AsyncIteratorProtocol {
    
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
            ConcurrentAsyncThrowingIteratorStream(source: consume self)
        }
    }
    
}

