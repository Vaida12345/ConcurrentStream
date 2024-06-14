//
//  ConcurrentCompactedStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 2024/3/31.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


fileprivate final class ConcurrentCompactedStream<Unwrapped, SourceStream>: ConcurrentStream where SourceStream: ConcurrentStream, SourceStream.Element == Optional<Unwrapped> {
    
    /// The source stream
    private let source: SourceStream
    
    fileprivate init(source: consuming SourceStream) {
        self.source = source
    }
    
    func next() async throws(Failure) -> Element? {
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
    
    nonisolated var cancel: @Sendable () -> Void {
        { [_cancel = source.cancel] in
            _cancel()
        }
    }
    
    typealias Element = Unwrapped
    
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
    public consuming func compacted<Unwrapped>() -> some ConcurrentStream<Unwrapped, Failure> where Element == Unwrapped? {
        ConcurrentCompactedStream(source: consume self)
    }
    
}
