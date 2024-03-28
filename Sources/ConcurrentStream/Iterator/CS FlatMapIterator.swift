//
//  ConcurrentFlatMapStream Iterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
internal struct ConcurrentFlatMapStreamIterator<SourceIterator, SegmentOfResult>: ConcurrentStreamIterator where SourceIterator: ConcurrentStreamIterator, SegmentOfResult: ConcurrentStream {
    
    // MARK: - Instance Stored Properties
    
    private var source: any ConcurrentStreamIterator<SegmentOfResult>
    
    
    private var currentProvider: SegmentOfResult.Iterator? = nil
    
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
                currentProvider = await nextStream.makeAsyncIterator(sorted: true)
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
    internal init(iterator: SourceIterator, work: @escaping (_ element: SourceIterator.Element) async throws -> SegmentOfResult?) async {
        self.source = await ConcurrentMapStream(source: iterator, work: work).makeAsyncIterator(sorted: true)
    }
    
    
    
    // MARK: - Convenience Initializers
    
    
    
    // MARK: - Type Properties
    
    
    // MARK: - Type Methods
    
    
    // MARK: - Operators
    
    
    // MARK: - Type Alies
    
    @usableFromInline
    internal typealias Element = SegmentOfResult.Element
    
    
    // MARK: - Substructures
    
    
    // MARK: - Subscript
    
}
