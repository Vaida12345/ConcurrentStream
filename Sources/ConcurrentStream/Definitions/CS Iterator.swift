//
//  ConcurrentStream Iterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


/// An iterator to a concurrent stream.
@rethrows
public protocol ConcurrentStreamIterator<Element>: AsyncIteratorProtocol where Element: Sendable {
    
    /// A raw iterator is one that does not require any work to obtain `next`.
    var isRawIterator: Bool { get }
    
    /// Returns the next element in the iterator.
    ///
    /// - Returns: The next element in the iterator, `nil` when reached the end.
    ///
    /// - throws: rethrows whatever is thrown in the definition.
    mutating func next() async throws -> Element?
    
    /// Cancels the task of obtaining iterator.
    func cancel()
    
}
