//
//  ConcurrentUniqueStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 2024/3/31.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
final class ConcurrentUniqueStream<SourceStream>: ConcurrentStream where SourceStream: ConcurrentStream, SourceStream.Element: Hashable, SourceStream.Element: Sendable {
    
    /// The source stream
    @usableFromInline
    let source: SourceStream
    
    @usableFromInline
    let store = Store()
    
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
            guard let next = try await source.next() else { return nil }
            if await self.store.insert(next) {
                return next
            }
            
            return try await self.next()
        } catch {
            self.cancel()
            throw error
        }
    }
    
    @usableFromInline
    typealias Element = SourceStream.Element
    
    @usableFromInline
    typealias Failure = SourceStream.Failure
    
    
    @usableFromInline
    actor Store {
        
        @usableFromInline
        var set: Set<Element> = []
        
        @inlinable
        func insert(_ element: Element) -> Bool {
            self.set.insert(element).inserted
        }
        
    }
    
}


extension ConcurrentStream {
    
    /// Removes the repeated elements of the stream, leaving only the entries different from each other.
    ///
    /// The overhead of this method is kept minimum. It would perform the same as `Sequence.unique()`.
    ///
    /// > Example:
    /// >
    /// > ```swift
    /// > [1, 2, 3, 1].stream.unique() // [1, 2, 3]
    /// > ```
    ///
    /// - Returns: The array without repeated elements.
    ///
    /// - Complexity: This method does not involve the creation of a new `taskGroup`.
    @inlinable
    public consuming func unique() -> some ConcurrentStream<Element, Failure> where Element: Hashable, Element: Sendable {
        ConcurrentUniqueStream(source: consume self)
    }
    
}
