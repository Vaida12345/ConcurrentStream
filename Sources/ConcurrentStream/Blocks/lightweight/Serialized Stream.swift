//
//  ConcurrentStream Serialized Iterator.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


private final class ConcurrentSerializedStream<LHS, RHS>: ConcurrentStream where LHS: ConcurrentStream, RHS: ConcurrentStream, LHS.Element == RHS.Element {
    
    private let lhs: LHS
    
    private let rhs: RHS
    
    
    func next() async throws(Failure) -> Element? {
        do {
            if let lhs = try await lhs.next() { return lhs }
            return try await rhs.next()
        } catch {
            self.cancel()
            throw error
        }
    }
    
    consuming func cancel() {
        lhs.cancel()
        rhs.cancel()
    }
    
    
    fileprivate init(lhs: consuming LHS, rhs: consuming RHS) {
        self.lhs = lhs
        self.rhs = rhs
    }
    
    typealias Element = LHS.Element
    
    typealias Failure = any Error
    
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
    ///
    /// - Throws: Sadly, there is no way to obtain the thrown error, even with typed throws.
    public static func + (_ lhs: consuming Self, _ rhs: consuming some ConcurrentStream<Element, some Error>) -> some ConcurrentStream<Element, any Error> {
        ConcurrentSerializedStream(lhs: consume lhs, rhs: consume rhs)
    }

}

