//
//  ConcurrentCompactStream Iterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

/*
@usableFromInline
internal struct ConcurrentCompactStreamIterator<Unwrapped>: ConcurrentStreamIterator where Unwrapped: Sendable {
    
    // MARK: - Instance Stored Properties
    
    private var source: any ConcurrentStreamIterator<Unwrapped?>
    
    
    // MARK: - Computed Instance Properties
    
    
    // MARK: - Instance Methods
    
    @usableFromInline
    internal mutating func next() async throws -> Element? {
        while let next = try await source.next() {
            if let next { return next }
        }
        
        return nil
    }
    
    
    // MARK: - Designated Initializers
    
    @usableFromInline
    internal init(stream: some ConcurrentStream<Unwrapped?>) async {
        self.source = await stream.makeAsyncIterator(sorted: true)
    }
    
    
    
    // MARK: - Convenience Initializers
    
    
    
    // MARK: - Type Properties
    
    
    // MARK: - Type Methods
    
    
    // MARK: - Operators
    
    
    // MARK: - Type Alies
    
    @usableFromInline
    internal typealias Element = Unwrapped
    
    
    // MARK: - Substructures
    
    
    // MARK: - Subscript
    
}
*/
