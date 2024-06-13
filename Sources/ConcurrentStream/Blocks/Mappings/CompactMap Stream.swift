//
//  ConcurrentCompactMapStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


extension ConcurrentStream {
    
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
    /// - Throws: Sadly, there is no way to obtain the thrown error, even with typed throws.
    ///
    /// ## Topics
    /// ### Lightweight Equivalent
    /// The lightweight equivalent performs much better when transformation is not required.
    ///
    /// - ``compacted()``
    public consuming func compactMap<T>(_ transform: @Sendable @escaping (Self.Element) async throws -> Optional<T>) async -> some ConcurrentStream<T, any Error> {
        await self.map(transform).compacted()
    }
    
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
    /// - Throws: Sadly, there is no way to obtain the thrown error, even with typed throws.
    ///
    /// ## Topics
    /// ### Lightweight Equivalent
    /// The lightweight equivalent performs much better when transformation is not required.
    ///
    /// - ``compacted()``
    public consuming func compactMap<T>(_ transform: @Sendable @escaping (Self.Element) async -> Optional<T>) async -> some ConcurrentStream<T, Failure> {
        await self.map(transform).compacted()
    }
    
}


extension ConcurrentStream where Failure == Never {
    
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
    /// - Throws: Sadly, there is no way to obtain the thrown error, even with typed throws.
    ///
    /// ## Topics
    /// ### Lightweight Equivalent
    /// The lightweight equivalent performs much better when transformation is not required.
    ///
    /// - ``compacted()``
    public consuming func compactMap<T, E>(_ transform: @Sendable @escaping (Self.Element) async throws(E) -> Optional<T>) async -> some ConcurrentStream<T, E> where E: Error {
        await self.map(transform).compacted()
    }
    
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
    /// - Throws: Sadly, there is no way to obtain the thrown error, even with typed throws.
    ///
    /// ## Topics
    /// ### Lightweight Equivalent
    /// The lightweight equivalent performs much better when transformation is not required.
    ///
    /// - ``compacted()``
    public consuming func compactMap<T, E>(_ transform: @Sendable @escaping (Self.Element) async -> Optional<T>) async -> some ConcurrentStream<T, Never> {
        await self.map(transform).compacted()
    }
    
}
