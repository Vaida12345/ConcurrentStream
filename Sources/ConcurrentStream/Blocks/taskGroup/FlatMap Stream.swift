//
//  ConcurrentFlatMapStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

extension ConcurrentStream {
    
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
    /// - ``flatten()``
    public consuming func flatMap<T>(_ transform: @Sendable @escaping (Self.Element) async throws -> some  ConcurrentStream<T>) async -> some ConcurrentStream<T> {
        await self.map(transform).flatten()
    }
    
}
