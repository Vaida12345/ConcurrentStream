//
//  ConcurrentStream.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


// Documentation in DocC.
@rethrows
public protocol ConcurrentStream<Element> {
    
    /// The base that provides the contents to the stream.
    var source: SourceIterator { get }
    
    /// Transforms elements of the source.
    ///
    /// The existence of the result is marked by the optional.
    func build(source: SourceIterator.Element) async throws -> Element?
    
    /// Creates the asynchronous iterator that produces elements of this stream.
    ///
    /// An ``ConcurrentStreamIterator`` (stream, single-threaded) can be retrieved given ``makeAsyncIterator(sorted:)``. The unsorted iterator requires do not buffer and hence performs slightly better.
    ///
    /// The iterator is optimized, and overhead is kept minimum when it is a ``ConcurrentStreamSequence``.
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
    /// for i in 1...1000 {
    ///
    /// }
    /// ```
    ///
    /// To cancel the task of iterator, call ``ConcurrentStreamIterator/cancel()``.
    ///
    /// - Warning: A default implementation exists and is preferred.
    ///
    /// - Important: When using a `Task { }` to obtain `next`, remember to mark the priority of the `Task` above `.medium`, otherwise the system would try to complete the iterator before entering the task.
    ///
    /// - Parameters:
    ///   - sorted: Whether the iterator should produce the elements in order.
    func makeAsyncIterator(sorted: Bool) async -> Iterator
    
    /// The type of the output of stream
    associatedtype Element: Sendable where Element == Iterator.Element
    
    /// The iterator that provides the source stream.
    associatedtype SourceIterator: ConcurrentStreamIterator
    
    associatedtype Iterator: ConcurrentStreamIterator 
    
}
