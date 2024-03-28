//
//  ConcurrentUniqueStream.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
internal struct ConcurrentUniqueStream<Element, SourceIterator>: ConcurrentStream where Element: Hashable, SourceIterator: ConcurrentStreamIterator {
    
    // MARK: - Instance Stored Properties
    
    @usableFromInline
    internal var source: SourceIterator
    
    @usableFromInline
    internal let work: (_: SourceIterator.Element) async throws -> Element?
    
    @usableFromInline
    internal var produced = IsolatedContent(Set<Int>())
    
    
    // MARK: - Computed Instance Properties
    
    
    // MARK: - Instance Methods
    
    @inlinable
    internal func build(source: SourceIterator.Element) async throws -> Element? {
        let result = try await work(source)
        let hash = result.hashValue
        guard await produced.transaction({ $0.insert(hash).inserted }) else { return nil }
        return result
    }
    
    @inlinable
    internal func makeAsyncIterator(sorted: Bool) async -> some ConcurrentStreamIterator<Element> {
        await _makeDefaultIterator(ordered: sorted)
    }
    
    
    // MARK: - Designated Initializers
    
    @inlinable
    internal init(source: SourceIterator, previousWork work: @escaping (_: SourceIterator.Element) async throws -> Element?) {
        self.source = source
        self.work = work
    }
    
    
    // MARK: - Convenience Initializers
    
    
    // MARK: - Type Properties
    
    
    // MARK: - Type Methods
    
    
    // MARK: - Operators
    
    
    // MARK: - Type Alies
    
    
    // MARK: - Substructures
    
    
    // MARK: - Subscript
    
}
