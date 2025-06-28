//
//  ConcurrentFlattenStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 2024/3/31.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
final class ConcurrentFlattenStream<SourceStream, Failure, ChildFailure>: ConcurrentStream where SourceStream: ConcurrentStream, SourceStream.Element: ConcurrentStream, Failure: Error, ChildFailure: Error, SourceStream.Element.Failure == ChildFailure {
    
    /// The source stream
    @usableFromInline
    let source: SourceStream
    
    @usableFromInline
    let cancel: @Sendable () -> Void
    
    /// The current iterating child of `source`.
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
            if let next = try await store.next() {
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
            throw error as! Failure
        }
    }
    
    @usableFromInline
    typealias Element = SourceStream.Element.Element
    
    @usableFromInline
    actor Store {
        
        @usableFromInline
        var stream: SourceStream.Element? = nil
        
        @inlinable
        func next() async throws -> sending Element? {
            try await stream?.next()
        }
        
        @inlinable
        func replace(stream: SourceStream.Element) {
            self.stream = stream
        }
        
    }
    
}


extension ConcurrentStream {
    
    // MARK: (SourceStream.Failure: some Error, ChildFailure: some Error)
    /// Returns a flat mapped stream.
    ///
    /// The overhead of this method is kept minimum. It would perform the same as `Sequence.flatten()`.
    ///
    /// - Complexity: This method does not involve the creation of a new `taskGroup`.
    ///
    /// ## Topics
    /// ### Variants
    /// These variants are implementation details, which are employed to ensure the proper throwing.
    /// - ``ConcurrentStream/flatten()-9xfyl``
    /// - ``ConcurrentStream/flatten()-618fa``
    /// - ``ConcurrentStream/flatten()-4mc14``
    ///
    /// ### Sequence Variant
    /// The following is used to ensure the capability with `Sequence`
    /// - ``ConcurrentStream/flatten()-6zgjd``
    @inlinable
    public consuming func flatten<T, E>() -> some ConcurrentStream<T, any Error> where Element: ConcurrentStream<T, E>, E: Error {
        ConcurrentFlattenStream<Self, any Error, E>(source: consume self)
    }
    
    // MARK: (SourceStream.Failure: some Error, ChildFailure: Never)
    /// Returns a flat mapped stream.
    ///
    /// This is a variant of ``ConcurrentStream/flatten()-3mp1s``
    @inlinable
    public consuming func flatten<T>() -> some ConcurrentStream<T, Failure> where Element: ConcurrentStream<T, Never> {
        ConcurrentFlattenStream<Self, Failure, Never>(source: consume self)
    }
    
}


extension ConcurrentStream where Failure == Never {
    
    // MARK: (SourceStream.Failure: Never, ChildFailure: some Error)
    /// Returns a flat mapped stream.
    ///
    /// This is a variant of ``ConcurrentStream/flatten()-3mp1s``
    @inlinable
    public consuming func flatten<T, E>() -> some ConcurrentStream<T, E> where Element: ConcurrentStream<T, E>, E: Error {
        ConcurrentFlattenStream<Self, E, E>(source: consume self)
    }
    
    // MARK: (SourceStream.Failure: Never, ChildFailure: Never)
    /// Returns a flat mapped stream.
    ///
    /// This is a variant of ``ConcurrentStream/flatten()-3mp1s``
    @inlinable
    public consuming func flatten<T>() -> some ConcurrentStream<T, Never> where Element: ConcurrentStream<T, Never> {
        ConcurrentFlattenStream<Self, Never, Never>(source: consume self)
    }
    
}
