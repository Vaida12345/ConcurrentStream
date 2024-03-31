//
//  ConcurrentStream Extensions.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


extension ConcurrentStream {
    
    /// Converts the stream to an `Array`.
    ///
    /// - returns: The returned `sequence` is in the same order as the input. The returned array is populated on return.
    ///
    /// - Complexity: O(*n*).
    @inlinable
    public var sequence: Array<Element> {
        consuming get async throws {
            var array: [Element] = []
            
            while let next = try await self.next() {
                array.append(next)
            }
            
            return array
        }
    }
    
    /// Calls the given closure on each element in the stream using a `taskGroup`.
    ///
    /// The `body` is called concurrently. To call in serial, use ``async`` instead.
    ///
    /// > Tip:
    /// > Due to the design of ``ConcurrentStream``, instead of looping and adding tasks to a `taskGroup`, you could use the `forEach` function.
    /// > ```swift
    /// > await (0...index).stream.forEach(...)
    /// > ```
    /// > This function is equivalent to the following in both performance and result
    /// > ```
    /// > await withTaskGroup(of: Int.self) { taskGroup in
    /// >     for (i, e) in (0...index).enumerated() {
    /// >         taskGroup.addTask(...)
    /// >     }
    /// > }
    /// > ```
    ///
    /// - Complexity: A `taskGroup` is created to enumerate the values.
    ///
    /// - Returns: The function is returned after the `taskGroup` completes.
    ///
    /// - Parameters:
    ///   - body: A closure that takes an element of the sequence as a parameter.
    ///   - index: The index of the element.
    ///   - element: The contained value of the element.
    @inlinable
    public func forEach(_ body: @escaping @Sendable (_ index: Int, _ element: Element) async throws -> Void) async throws {
        if #available(macOS 14, iOS 17, watchOS 10, tvOS 17, *) {
            try await withThrowingDiscardingTaskGroup { group in
                var index = 0
                while let next = try await self.next() {
                    let _index = index
                    group.addTask {
                        try Task.checkCancellation()
                        try await body(_index, next)
                    }
                    index &+= 1
                }
            }
        } else {
            try await withThrowingTaskGroup(of: Void.self) { group in
                var index = 0
                while let next = try await self.next() {
                    let _index = index
                    group.addTask {
                        try Task.checkCancellation()
                        try await body(_index, next)
                    }
                    index &+= 1
                }
            }
        }
    }
    
}


/*
extension ConcurrentStream {
    
    /// Creates a concurrent stream that maps the given closure over the stream’s elements, omitting results that don’t return a value.
    ///
    /// - Parameters:
    ///   - type: The unwrapped return type. One can provide this explicitly to ease the pain on the compiler (and hence the programmer).
    ///   - transform: A mapping closure. transform accepts an element of this sequence as its parameter and returns a transformed value of the same or of a different type.
    ///
    /// - Complexity: O(*n*), lazily.
    @inlinable
    public func compactMap<T>(to type: T.Type = T.self, _ transform: @escaping @Sendable (Element) async throws -> T?) async -> some ConcurrentStream<T> where T: Sendable {
        ConcurrentMapStream(source: self.source) {
            guard let element = try await self.build(source: $0) else { return nil }
            return try await transform(element)
        }
    }
    
    /// Creates a concurrent stream containing the concatenated results of calling the given transformation with each element of this stream.
    ///
    /// In the `transform` closure, a stream is required.
    ///
    /// ```swift
    /// (0..<10).stream
    ///     .flatMap {
    ///         [Int](0..<10).stream
    ///     }
    /// ```
    ///
    /// In the complicated cases where an `any ConcurrentStream<Element>` is returned (instead of `some ConcurrentStream<Element>`), method of this same signature is called instead. This is automatically handled by the compiler.
    ///
    /// - Note: `nil` values in the inner stream are also omitted, unless indicated otherwise by `type`.
    ///
    /// - Parameters:
    ///   - type: The element type of the returned stream. One can provide this explicitly to ease the pain on the compiler (and hence the programmer).
    ///   - transform: A mapping closure. transform accepts an element of this sequence as its parameter and returns a transformed value of the same or of a different type.
    ///
    /// - Complexity: O(*n*), lazily.
    @inlinable
    public func flatMap<SegmentOfResult>(toStreamOf type: SegmentOfResult.Element.Type = SegmentOfResult.Element.self, _ transform: @escaping @Sendable (Element) async throws -> SegmentOfResult?) async -> some ConcurrentStream<SegmentOfResult.Element> where SegmentOfResult: ConcurrentStream {
        await ConcurrentStreamSequence(iterator: ConcurrentFlatMapStreamIterator<SourceIterator, SegmentOfResult>(iterator: self.source) {
            guard let element = try await self.build(source: $0) else { return nil }
            return try await transform(element)
        })
    }
    
    /// Creates a concurrent stream containing the concatenated results of calling the given transformation with each element of this stream.
    ///
    /// In the `transform` closure, a stream is required.
    ///
    /// ```swift
    /// (0..<10).stream
    ///     .flatMap {
    ///         [Int](0..<10).stream
    ///     }
    /// ```
    ///
    /// In the simple cases where an `some ConcurrentStream<Element>` is returned (instead of `any ConcurrentStream<Element>`), method of this same signature is called instead. This is automatically handled by the compiler.
    ///
    /// - Note: `nil` values in the inner stream are also omitted, unless indicated otherwise by `type`.
    ///
    /// - Parameters:
    ///   - type: The element type of the returned stream. One can provide this explicitly to ease the pain on the compiler (and hence the programmer).
    ///   - transform: A mapping closure. transform accepts an element of this sequence as its parameter and returns a transformed value of the same or of a different type.
    ///
    /// - Complexity: O(*n*), lazily.
    @inlinable
    public func flatMap<T>(toStreamOf type: T.Type = T.self, _ transform: @escaping @Sendable (Element) async throws -> (any ConcurrentStream<T>)?) async -> some ConcurrentStream<T> {
        await ConcurrentStreamSequence(iterator: ConcurrentAnyFlatMapStreamIterator<SourceIterator, T>(source: self.source) {
            guard let element = try await self.build(source: $0) else { return nil }
            return try await transform(element)
        })
    }
}
*/
