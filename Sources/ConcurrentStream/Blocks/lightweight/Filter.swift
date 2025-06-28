//
//  FilterStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/3/24.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

import Foundation


@usableFromInline
final class ConcurrentFilterStream<SourceStream, Failure>: ConcurrentStream where SourceStream: ConcurrentStream, Failure: Error {
    
    /// The source stream
    @usableFromInline
    let source: SourceStream
    
    @usableFromInline
    let isIncluded: (Element) async throws -> Bool
    
    @inlinable
    init(source: consuming SourceStream, isIncluded: @escaping (Element) async throws -> Bool) {
        self.source = source
        self.isIncluded = isIncluded
    }
    
    @inlinable
    func next() async throws(Failure) -> Element? {
        do {
            guard let next = try await source.next() else { return nil }
            if try await isIncluded(next) {
                return next
            }
            
            return try await self.next()
        } catch {
            self.cancel()
            throw error as! Failure
        }
    }
    
    @inlinable
    nonisolated var cancel: @Sendable () -> Void {
        { [_cancel = source.cancel] in
            _cancel()
        }
    }
    
    @usableFromInline
    typealias Element = SourceStream.Element
    
}


extension ConcurrentStream {
    
    // MARK: (SourceStream.Failure: some Error, isIncluded: some Error)
    /// Returns an stream containing, in order, the elements of the stream that satisfy the given predicate.
    ///
    /// The overhead of this method is kept minimum. It would perform the same as `Sequence.filter(_:)`.
    ///
    /// > Example:
    /// >
    /// > ```swift
    /// > [1, 2, 3, 1].stream.filter(\.isEven) // [2]
    /// > ```
    ///
    /// - Returns: The stream all of whose elements match `isIncluded`.
    ///
    /// - Important: There is **no way** to retrieve the discarded elements. A stream is not copyable. (Although in this implementation, it is copy-by-reference.)
    ///
    /// - Complexity: This method does not involve the creation of a new `taskGroup`.
    ///
    /// ## Topics
    /// ### Variants
    /// These variants are implementation details, which are employed to ensure the proper throwing.
    /// - ``ConcurrentStream/filter(_:)-16976``
    /// - ``ConcurrentStream/filter(_:)-35xli``
    /// - ``ConcurrentStream/filter(_:)-2kl80``
    @inlinable
    public consuming func filter(_ isIncluded: @escaping (Element) async throws -> Bool) -> some ConcurrentStream<Element, any Error> {
        ConcurrentFilterStream(source: consume self, isIncluded: isIncluded)
    }
    
    // MARK: (SourceStream.Failure: some Error, isIncluded: Never)
    /// Returns an stream containing, in order, the elements of the stream that satisfy the given predicate.
    ///
    /// This is a variant of ``ConcurrentStream/filter(_:)-5v6w8``
    @inlinable
    public consuming func filter(_ isIncluded: @escaping (Element) async -> Bool) -> some ConcurrentStream<Element, Failure> {
        ConcurrentFilterStream(source: consume self, isIncluded: isIncluded)
    }
    
}


extension ConcurrentStream where Failure == Never {
    
    // MARK: (SourceStream.Failure: Never, isIncluded: some Error)
    // FIXME: Currently not called, swift choose to use the first one instead.
    /// Returns an stream containing, in order, the elements of the stream that satisfy the given predicate.
    ///
    /// This is a variant of ``ConcurrentStream/filter(_:)-5v6w8``
    @inlinable
    public consuming func filter<E>(_ isIncluded: @escaping (Element) async throws(E) -> Bool) -> some ConcurrentStream<Element, E> {
        ConcurrentFilterStream(source: consume self, isIncluded: isIncluded)
    }
    
    // MARK: (SourceStream.Failure: Never, isIncluded: Never)
    /// Returns an stream containing, in order, the elements of the stream that satisfy the given predicate.
    ///
    /// This is a variant of ``ConcurrentStream/filter(_:)-5v6w8``
    @inlinable
    public consuming func filter(_ isIncluded: @escaping (Element) async -> Bool) -> some ConcurrentStream<Element, Never> {
        ConcurrentFilterStream(source: consume self, isIncluded: isIncluded)
    }
    
}
