//
//  ConcurrentAnyFlatMapStream Iterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
internal struct ConcurrentAnyFlatMapStreamIterator<SourceIterator, Element>: ConcurrentStreamIterator where SourceIterator: ConcurrentStreamIterator {
    
    // MARK: - Instance Stored Properties
    
    private var source: any ConcurrentStreamIterator<any ConcurrentStream<Element>>
    
    private var currentProvider: (any ConcurrentStreamIterator<Element>)? = nil
    
    @usableFromInline
    var isRawIterator: Bool { false }
    
    
    // MARK: - Computed Instance Properties
    
    
    // MARK: - Instance Methods
    
    @usableFromInline
    internal mutating func next() async throws -> Element? {
        var next: Element? = nil
        
        while next == nil {
            next = try await currentProvider?.next()
            if next == nil {
                let nextStream = try await source.next()
                guard let nextStream else { return nil }
                
                currentProvider = (await nextStream.makeAsyncIterator(sorted: true) as any ConcurrentStreamIterator<Element>)
            }
        }
        
        return next
    }
    
    @usableFromInline
    internal func cancel() {
        source.cancel()
        currentProvider?.cancel()
    }
    
    
    // MARK: - Designated Initializers
    
    @usableFromInline
    internal init(source: SourceIterator, work: @escaping (_ element: SourceIterator.Element) async throws -> (any ConcurrentStream<Element>)?) async {
        self.source = await ConcurrentMapStream(source: source, work: work).makeAsyncIterator(sorted: true)
        self.currentProvider = nil
    }
    
    
    
    // MARK: - Convenience Initializers
    
    
    
    // MARK: - Type Properties
    
    
    // MARK: - Type Methods
    
    
    // MARK: - Operators
    
    
    // MARK: - Type Alies
    
    
    // MARK: - Substructures
    
    
    // MARK: - Subscript
    
}
