//
//  ConcurrentStream Sequence.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//



/// A general Sequence based on ``ConcurrentStreamIterator``.
///
/// This sequence expects ``ConcurrentStreamIterator/next()`` to be a O(*1*) operation.
public struct ConcurrentStreamSequence<Iterator>: ConcurrentStream where Iterator: ConcurrentStreamIterator, Iterator.Element: Sendable {
    
    /// The iterator of the sequence.
    public var source: Iterator
    
    /// An `@inlinable` function that maps the elements of `source` as it is.
    @inlinable
    public func build(source: Element) -> Iterator.Element? {
        source
    }
    
    /// Creates the asynchronous iterator that produces elements of this stream.
    ///
    /// An ``ConcurrentStreamIterator`` (stream, single-threaded) can be retrieved given ``makeAsyncIterator(sorted:)``. The unsorted iterator requires do not buffer and hence performs slightly better.
    ///
    /// The iterator is optimized, and overhead is kept minimum.
    ///
    /// ```swift
    /// try await (1...1000)
    ///     .stream
    ///     .enumerate { index, value in
    ///
    ///     }
    /// ```
    ///
    /// This performs the same as
    ///
    /// ```swift
    /// @concurrent
    /// for i in 1...1000 {
    ///     
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - sorted: Whether the iterator should produce the elements in order.
    @inlinable
    public func makeAsyncIterator(sorted: Bool) async -> Iterator {
        self.source
    }
    
    /// Creates a sequence with the given iterator.
    @inlinable
    public init(iterator: Iterator) {
        self.source = iterator
    }
    
    /// The Element of iterator.
    public typealias Element = Iterator.Element
    
}
