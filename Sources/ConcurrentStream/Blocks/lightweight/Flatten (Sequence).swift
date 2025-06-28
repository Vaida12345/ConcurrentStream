//
//  ConcurrentSequenceFlattenStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 2024/3/31.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
final class ConcurrentSequenceFlattenStream<SourceStream>: ConcurrentStream where SourceStream: ConcurrentStream, SourceStream.Element: Sequence {
    
    /// The source stream
    @usableFromInline
    let source: SourceStream
    
    /// The current iterating child of `source`.
    @usableFromInline
    var stream: SourceStream.Element.Iterator? = nil
    
    @inlinable
    init(source: consuming SourceStream) {
        self.source = source
    }
    
    @inlinable
    func next() async throws(Failure) -> Element? {
        do {
            if let next = stream?.next() {
                return next
            }
            
            // the current stream is drain, get next one
            guard let nextStream = try await source.next() else {
                // no next stream, exit
                return nil
            }
            
            self.stream = nextStream.makeIterator()
            return try await self.next()
        } catch {
            self.cancel()
            throw error
        }
    }
    
    @inlinable
    nonisolated var cancel: @Sendable () -> Void {
        { [_cancel = source.cancel] in
            _cancel()
        }
    }
    
    @usableFromInline
    typealias Element = SourceStream.Element.Element
    
    @usableFromInline
    typealias Failure = SourceStream.Failure
    
}


extension ConcurrentStream {
    
    /// Returns a flat mapped stream.
    ///
    /// The overhead of this method is kept minimum. It would perform the same as `Sequence.flatten()`.
    ///
    /// - Complexity: This method does not involve the creation of a new `taskGroup`.
    @inlinable
    public consuming func flatten<T>() -> some ConcurrentStream<T, Failure> where Element: Sequence<T> {
        ConcurrentSequenceFlattenStream(source: consume self)
    }
    
}
