//
//  ConcurrentStream Iterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


/// An iterator to a concurrent stream.
///
/// This protocol is a class protocol, due to the fact that
/// - A class protocol has a `deinit` block, where the task can be cancelled.
/// - A class protocol has non-mutating next, making the following way of cancelation possible:
/// ```swift
/// let iterator = await ConcurrentStreamOrderedIterator(stream: stream)
///
/// try await withTaskCancellationHandler {
///     for _ in 0...1000 {
///         heavyWork(i: 0)
///     }
///
///     while let next = try await iterator.next() {
///         ...
///     }
/// } onCancel: {
///     iterator.cancel()
/// }
/// ```
@rethrows
public protocol ConcurrentStreamIterator<Element>: AsyncIteratorProtocol, AnyObject where Element: Sendable {
    
    
    /// Returns the next element in the iterator.
    ///
    /// - Returns: The next element in the iterator, `nil` when reached the end.
    ///
    /// - throws: rethrows whatever is thrown in the definition.
    func next() async throws -> Element?
    
    /// Cancels the task of obtaining iterator.
    func cancel()
    
}
