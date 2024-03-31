//
//  ConcurrentStream Serialized Iterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


private final class ConcurrentSerializedStream<LHS, RHS>: ConcurrentStream where LHS: ConcurrentStream, RHS: ConcurrentStream, LHS.Element == RHS.Element {
    
    private var lhs: LHS
    
    private var rhs: RHS
    
    
    fileprivate func next() async throws -> Element? {
        if let lhs = try await lhs.next() { return lhs }
        return try await rhs.next()
    }
    
    fileprivate func cancel() {
        lhs.cancel()
        rhs.cancel()
    }
    
    
    fileprivate init(lhs: LHS, rhs: RHS) {
        self.lhs = lhs
        self.rhs = rhs
    }
    
    typealias Element = LHS.Element
    
}


extension ConcurrentStream {

    /// Creates a new stream by concatenating the elements of two streams.
    ///
    /// The overhead of this method is kept minimum. It would perform the same as `Sequence.+(:_:_)`.
    ///
    /// - Parameters:
    ///   - lhs: The current stream
    ///   - rhs: Another stream to be iterated at the end of current stream.
    ///
    /// - Complexity: This method does not involve the creation of a new `taskGroup`.
    public static func + (_ lhs: Self, _ rhs: some ConcurrentStream<Element>) -> some ConcurrentStream<Element> {
        ConcurrentSerializedStream(lhs: lhs, rhs: rhs)
    }

}

