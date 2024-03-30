//
//  ConcurrentUniqueStream.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

/*
internal struct ConcurrentUniqueStream<Element, SourceIterator>: ConcurrentStream where Element: Hashable, SourceIterator: ConcurrentStreamIterator {
    
    // MARK: - Instance Stored Properties
    
    internal var source: SourceIterator
    
    internal let work: (_: SourceIterator.Element) async throws -> Element?
    
    private var produced = IsolatedContent(Set<Int>())
    
    
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


/// A wrapper to the content such that it can be mutated concurrently.
private final actor IsolatedContent<Content> {
    
    /// The wrapped content.
    private var content: Content
    
    /// Obtain the current value.
    func get() -> Content {
        self.content
    }
    
    /// A logical unit of work that must either be entirely completed or aborted (indivisible, atomic).
    ///
    /// Any mutation to the wrapped content should use this method. Do put heavy work into this closure, as this closure is isolated to this actor, putting heavy work continuously will result in a queue.
    ///
    /// The ``get()`` function should not be called inside this closure, which is prevented by the complier, nor should be called in the same context, use ``transaction(_:)`` to return the current value.
    func transaction<Result>(_ mutate: (inout Content) throws -> Result) rethrows -> Result {
        try mutate(&content)
    }
    
    /// Creates a wrapper with its initial value.
    init(_ content: Content) {
        self.content = content
    }
    
}
*/
