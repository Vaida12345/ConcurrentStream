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
    
    fileprivate init(source: SourceStream) {
        self.source = source
    }
    
    func next() async throws -> Element? {
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
    
    func cancel() {
        self.source.cancel()
    }
    
    typealias Element = Unwrapped
    
}


extension ConcurrentStream {
    
    /// Returns a compact mapped stream.
    ///
    /// The overhead of this method is kept minimum. It would perform the same as `Sequence.compacted()`.
    ///
    /// - Complexity: This method does not involve the creation of a new `taskGroup`.
    public consuming func compacted<Unwrapped>() -> some ConcurrentStream<Unwrapped> where Element == Unwrapped? {
        ConcurrentCompactedStream(source: self)
    }
    
}
