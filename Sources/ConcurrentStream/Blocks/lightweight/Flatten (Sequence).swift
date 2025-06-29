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
    
    @usableFromInline
    let cancel: @Sendable () -> Void
    
    @usableFromInline
    let store = Store()
    
    @inlinable
    init(source: SourceStream) {
        self.source = source
        self.cancel = source.cancel
    }
    
    @inlinable
    func next() async throws(Failure) -> sending Element? {
        do {
            if let next = await self.store.next() {
                return next
            }
            
            // the current stream is drain, get next one
            guard let nextStream = try await source.next() else {
                // no next stream, exit
                return nil
            }
            
            await self.store.replace(stream: nextStream)
            return try await self.next()
        } catch {
            self.cancel()
            throw error
        }
    }
    
    @usableFromInline
    typealias Element = SourceStream.Element.Element
    
    @usableFromInline
    typealias Failure = SourceStream.Failure
    
    @usableFromInline
    actor Store {
        
        /// The current iterating child of `source`.
        @usableFromInline
        var stream: SourceStream.Element.Iterator? = nil
        
        @inlinable
        func next() -> sending Element? {
            let removed = self.stream?.next()
            return removed.map(\.self) // workaround: shallow copy to trick compiler to think it is detached from memory. This is safe nevertheless, as `self` no longer has access to `removed`.
        }
        
        @inlinable
        func replace(stream: SourceStream.Element) {
            self.stream = stream.makeIterator()
        }
        
    }
    
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
