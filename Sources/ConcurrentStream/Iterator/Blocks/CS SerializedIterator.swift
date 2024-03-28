//
//  ConcurrentStream Serialized Iterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


private struct ConcurrentStreamSerializedIterator<Element>: ConcurrentStreamIterator {
    
    private var lhs: any ConcurrentStreamIterator<Element>
    
    private var rhs: any ConcurrentStreamIterator<Element>
    
    
    fileprivate mutating func next() async throws -> Element? {
        if let lhs = try await lhs.next() { return lhs }
        return try await rhs.next()
    }
    
    fileprivate func cancel() {
        lhs.cancel()
        rhs.cancel()
    }
    
    
    init(lhs: any ConcurrentStream<Element>, rhs: any ConcurrentStream<Element>) async {
        self.lhs = await lhs.makeAsyncIterator(sorted: true) as any ConcurrentStreamIterator<Element>
        self.rhs = await rhs.makeAsyncIterator(sorted: true) as any ConcurrentStreamIterator<Element>
    }
    
    init(lhs: some ConcurrentStream<Element>, rhs: some ConcurrentStream<Element>) async {
        self.lhs = await lhs.makeAsyncIterator(sorted: true)
        self.rhs = await rhs.makeAsyncIterator(sorted: true)
    }
    
    
}


extension ConcurrentStream {

    /// Creates a new stream by concatenating the elements of two streams.
    ///
    /// - Note: Work is dispatched on return.
    ///
    /// - Parameters:
    ///   - lhs: The current stream
    ///   - rhs: Another stream to be iterated at the end of current stream.
    public static func + (lhs: Self, rhs: some ConcurrentStream<Element>) async -> some ConcurrentStream<Element> {
        await ConcurrentStreamSequence(iterator: ConcurrentStreamSerializedIterator(lhs: lhs, rhs: rhs))
    }
    
    /// Creates a new stream by concatenating the elements of two streams.
    ///
    /// - Note: Work is dispatched on return.
    ///
    /// - Parameters:
    ///   - lhs: The current stream
    ///   - rhs: Another stream to be iterated at the end of current stream.
    public static func + (lhs: Self, rhs: any ConcurrentStream<Element>) async -> some ConcurrentStream<Element> {
        await ConcurrentStreamSequence(iterator: ConcurrentStreamSerializedIterator(lhs: lhs, rhs: rhs))
    }

}
