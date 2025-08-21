//
//  ConcurrentCompactMapStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


extension ConcurrentStream {
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: some Error)
    /// Creates a concurrent stream that compact maps the given closure over the stream’s elements.
    ///
    /// The `taskGroup` is created and dispatched; this function returns immediately.
    ///
    /// - Parameters:
    ///   - transform: A mapping closure. `transform` accepts an element of this sequence as its parameter and returns a transformed value of the same or of a different type.
    ///
    /// - Complexity: The process entails creating a new `taskGroup`.
    ///
    ///
    /// > Remark: This method is implemented as:
    /// > ```swift
    /// > self.map(transform).compact()
    /// > ```
    ///
    /// ## Topics
    /// ### Lightweight Equivalent
    /// The lightweight equivalent performs much better when transformation is not required.
    ///
    /// - ``compacted()``
    @inlinable
    public consuming func compactMap<T>(_ transform: @Sendable @escaping (Self.Element) async throws -> sending Optional<T>) -> some ConcurrentStream<T, any Error> {
        self.map(transform).compacted()
    }
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: Never)
    /// Creates a concurrent stream that compact maps the given closure over the stream’s elements.
    @inlinable
    public consuming func compactMap<T>(_ transform: @Sendable @escaping (Self.Element) async -> sending Optional<T>) -> some ConcurrentStream<T, Failure> {
        self.map(transform).compacted()
    }
    
}


extension ConcurrentStream where Failure == Never {
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: some Error)
    /// Creates a concurrent stream that compact maps the given closure over the stream’s elements.
    @inlinable
    public consuming func compactMap<T, E>(_ transform: @Sendable @escaping (Self.Element) async throws(E) -> sending Optional<T>) -> some ConcurrentStream<T, E> where E: Error {
        self.map(transform).compacted()
    }
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: Never)
    /// Creates a concurrent stream that compact maps the given closure over the stream’s elements.
    @inlinable
    public consuming func compactMap<T, E>(_ transform: @Sendable @escaping (Self.Element) async -> sending Optional<T>) -> some ConcurrentStream<T, Never> {
        self.map(transform).compacted()
    }
    
}
