//
//  ConcurrentMapStream.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
internal struct ConcurrentMapStream<Element, SourceIterator>: ConcurrentStream where SourceIterator: ConcurrentStreamIterator {
    
    // MARK: - Instance Stored Properties
    
    @usableFromInline
    internal var source: SourceIterator
    
    @usableFromInline
    internal let work: (_: SourceIterator.Element) async throws -> Element?
    
    
    // MARK: - Computed Instance Properties
    
    
    // MARK: - Instance Methods
    
    @inlinable
    internal func build(source: SourceIterator.Element) async throws -> Element? {
        try await work(source)
    }
    
    
    @inlinable
    internal func makeAsyncIterator(sorted: Bool) async -> some ConcurrentStreamIterator<Element> {
        await _makeDefaultIterator(ordered: sorted)
    }
    
    // MARK: - Designated Initializers
    
    @inlinable
    internal init(source: SourceIterator, work: @escaping (_: SourceIterator.Element) async throws -> Element?) {
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
