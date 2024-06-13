//
//  ConcurrentFlatMapStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

// MARK: - some Stream

extension ConcurrentStream {
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: some Error, ChildStreamError: some Error)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// The `taskGroup` is created and dispatched; this function returns immediately.
    ///
    /// > Remark: This method is implemented as:
    /// > ```swift
    /// > self.map(transform).flatten()
    /// > ```
    /// > This would ensure the concurrent generation of child streams, which are dispatched to generate their children on their creation.
    /// >
    /// > At last, the iterator in `flatten` collects these generated elements.
    ///
    /// - Parameters:
    ///   - transform: A mapping closure. `transform` accepts an element of this sequence as its parameter and returns a transformed value of the same or of a different type.
    ///
    /// - Complexity: The process entails creating a new `taskGroup`.
    ///
    /// ## Topics
    /// ### Lightweight Equivalent
    /// The lightweight equivalent performs much better when transformation is not required.
    ///
    /// - ``ConcurrentStream/flatten()-3mp1s``
    ///
    /// ### Variants
    /// These variants are implementation details, which are employed to ensure the proper throwing.
    /// - ``ConcurrentStream/flatMap(_:)-706tc``
    /// - ``ConcurrentStream/flatMap(_:)-4cwmq``
    /// - ``ConcurrentStream/flatMap(_:)-cdyd``
    /// - ``ConcurrentStream/flatMap(_:)-6ewvc``
    /// - ``ConcurrentStream/flatMap(_:)-32c9d``
    /// - ``ConcurrentStream/flatMap(_:)-4khfb``
    /// - ``ConcurrentStream/flatMap(_:)-5gccl``
    ///
    /// ### Sequence Variant
    /// The following is used to ensure the capability with `Sequence`
    /// - ``ConcurrentStream/flatMap(_:)-1kd8x``
    /// - ``ConcurrentStream/flatMap(_:)-9hxei``
    /// - ``ConcurrentStream/flatMap(_:)-j1vb``
    /// - ``ConcurrentStream/flatMap(_:)-7f9w5``
    public consuming func flatMap<T>(_ transform: @Sendable @escaping (Self.Element) async throws -> some ConcurrentStream<T, any Error>) async -> some ConcurrentStream<T, any Error> {
        await self.map(transform).flatten()
    }
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: some Error, ChildStreamError: Never)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/flatMap(_:)-6o6er``
    public consuming func flatMap<T>(_ transform: @Sendable @escaping (Self.Element) async throws -> some ConcurrentStream<T, Never>) async -> some ConcurrentStream<T, any Error> {
        await self.map(transform).flatten()
    }
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: Never, ChildStreamError: some Error)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/flatMap(_:)-6o6er``
    public consuming func flatMap<T>(_ transform: @Sendable @escaping (Self.Element) async -> some ConcurrentStream<T, some Error>) async -> some ConcurrentStream<T, any Error> {
        await self.map(transform).flatten()
    }
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: Never, ChildStreamError: Never)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/flatMap(_:)-6o6er``
    public consuming func flatMap<T>(_ transform: @Sendable @escaping (Self.Element) async -> some ConcurrentStream<T, Never>) async -> some ConcurrentStream<T, Failure> {
        await self.map(transform).flatten()
    }
    
}


extension ConcurrentStream where Failure == Never {
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: some Error, ChildStreamError: some Error)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/flatMap(_:)-6o6er``
    public consuming func flatMap<T>(_ transform: @Sendable @escaping (Self.Element) async throws -> some ConcurrentStream<T, some Error>) async -> some ConcurrentStream<T, any Error> {
        await self.map(transform).flatten()
    }
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: some Error, ChildStreamError: Never)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/flatMap(_:)-6o6er``
    public consuming func flatMap<T, E>(_ transform: @Sendable @escaping (Self.Element) async throws(E) -> some ConcurrentStream<T, Never>) async -> some ConcurrentStream<T, E> where E: Error {
        await self.map(transform).flatten()
    }
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: Never, ChildStreamError: some Error)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/flatMap(_:)-6o6er``
    public consuming func flatMap<T, E>(_ transform: @Sendable @escaping (Self.Element) async -> some ConcurrentStream<T, E>) async -> some ConcurrentStream<T, E> where E: Error {
        await self.map(transform).flatten()
    }
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: Never, ChildStreamError: Never)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/flatMap(_:)-6o6er``
    public consuming func flatMap<T>(_ transform: @Sendable @escaping (Self.Element) async -> some ConcurrentStream<T, Never>) async -> some ConcurrentStream<T, Never> {
        await self.map(transform).flatten()
    }
    
}


// MARK: - some Sequence

extension ConcurrentStream {
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: some Error)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/flatMap(_:)-6o6er``
    public consuming func flatMap<T>(_ transform: @Sendable @escaping (Self.Element) async throws -> some Sequence<T>) async -> some ConcurrentStream<T, any Error> {
        await self.map(transform).flatten()
    }
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: Never)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/flatMap(_:)-6o6er``
    public consuming func flatMap<T>(_ transform: @Sendable @escaping (Self.Element) async -> some Sequence<T>) async -> some ConcurrentStream<T, Failure> {
        await self.map(transform).flatten()
    }
    
}


extension ConcurrentStream where Failure == Never {
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: some Error)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/flatMap(_:)-6o6er``
    public consuming func flatMap<T, E>(_ transform: @Sendable @escaping (Self.Element) async throws(E) -> some Sequence<T>) async -> some ConcurrentStream<T, E> {
        await self.map(transform).flatten()
    }
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: Never)
    /// Creates a concurrent stream that flat maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/flatMap(_:)-6o6er``
    public consuming func flatMap<T>(_ transform: @Sendable @escaping (Self.Element) async -> some Sequence<T>) async -> some ConcurrentStream<T, Never> {
        await self.map(transform).flatten()
    }
    
}
