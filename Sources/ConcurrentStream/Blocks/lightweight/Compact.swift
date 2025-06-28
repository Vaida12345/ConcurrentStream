//
//  ConcurrentCompactedStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 2024/3/31.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
final class ConcurrentCompactedStream<Unwrapped, SourceStream>: ConcurrentStream where SourceStream: ConcurrentStream, SourceStream.Element == Optional<Unwrapped> {
    
    /// The source stream
    @usableFromInline
    let source: SourceStream
    
    @usableFromInline
    let cancel: @Sendable () -> Void
    
    @inlinable
    init(source: SourceStream) {
        self.source = source
        self.cancel = source.cancel
    }
    
    @inlinable
    func next() async throws(Failure) -> sending Element? {
        do {
            guard let next = try await source.next() else { return nil } // reaches end
            if let next {
                // unwraps `next`
                return next
            } else {
                return try await self.next()
            }
        } catch {
            self.cancel()
            throw error
        }
    }
    
    @usableFromInline
    typealias Element = Unwrapped
    
    @usableFromInline
    typealias Failure = SourceStream.Failure
    
}


extension ConcurrentStream {
    
    /// Returns a compact mapped stream.
    ///
    /// The overhead of this method is kept minimum. It would perform the same as `Sequence.compacted()`.
    ///
    /// - Complexity: This method does not involve the creation of a new `taskGroup`.
    ///
    /// - Tip: `map(_:).compacted()` would perform the same as `compactMap(_:)`, with similar performance.
    @inlinable
    public consuming func compacted<Unwrapped>() -> some ConcurrentStream<Unwrapped, Failure> where Element == Unwrapped? {
        ConcurrentCompactedStream(source: self)
    }
    
}
