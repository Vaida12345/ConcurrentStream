//
//  FilterStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/3/24.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

import Foundation


fileprivate final class ConcurrentFilterStream<SourceStream>: ConcurrentStream where SourceStream: ConcurrentStream {
    
    /// The source stream
    private let source: SourceStream
    
    private let isIncluded: (Element) async throws -> Bool
    
    fileprivate init(source: SourceStream, isIncluded: @escaping (Element) async throws -> Bool) {
        self.source = source
        self.isIncluded = isIncluded
    }
    
    func next() async throws -> Element? {
        do {
            guard let next = try await source.next() else { return nil }
            if try await isIncluded(next) {
                return next
            }
            
            return try await self.next()
        } catch {
            self.cancel()
            throw error
        }
    }
    
    func cancel() {
        self.source.cancel()
    }
    
    typealias Element = SourceStream.Element
    
}


extension ConcurrentStream {
    
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
    public consuming func filter(_ isIncluded: @escaping (Element) async throws -> Bool) -> some ConcurrentStream<Element> {
        ConcurrentFilterStream(source: self, isIncluded: isIncluded)
    }
    
}
