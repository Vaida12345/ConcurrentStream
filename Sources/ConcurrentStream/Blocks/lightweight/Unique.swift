//
//  ConcurrentUniqueStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 2024/3/31.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


fileprivate final class ConcurrentUniqueStream<SourceStream>: ConcurrentStream where SourceStream: ConcurrentStream, SourceStream.Element: Hashable {
    
    /// The source stream
    private let source: SourceStream
    
    private var set: Set<Int>
    
    fileprivate init(source: consuming SourceStream) {
        self.source = source
        self.set = []
    }
    
    func next() async throws(Failure) -> Element? {
        do {
            guard let next = try await source.next() else { return nil }
            let hash = next.hashValue
            if set.insert(hash).inserted {
                return next
            }
            
            return try await self.next()
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
    
    typealias Element = SourceStream.Element
    
    typealias Failure = SourceStream.Failure
    
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
    public consuming func unique() -> some ConcurrentStream<Element, Failure> where Element: Hashable {
        ConcurrentUniqueStream(source: consume self)
    }
    
}