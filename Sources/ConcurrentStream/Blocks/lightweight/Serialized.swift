//
//  ConcurrentStream Serialized Iterator.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
final class ConcurrentSerializedStream<LHS, RHS, Failure>: ConcurrentStream where LHS: ConcurrentStream, RHS: ConcurrentStream, LHS.Element == RHS.Element, Failure: Error {
    
    @usableFromInline
    let lhs: LHS
    
    @usableFromInline
    let rhs: RHS
    
    @inlinable
    func next() async throws(Failure) -> Element? {
        do {
            if let lhs = try await lhs.next() { return lhs }
            return try await rhs.next()
        } catch {
            self.cancel()
            throw error as! Failure
        }
    }
    
    @inlinable
    nonisolated var cancel: @Sendable () -> Void {
        { [ _lhs = lhs.cancel, _rhs = rhs.cancel] in
            _lhs()
            _rhs()
        }
    }
    
    @inlinable
    init(lhs: consuming LHS, rhs: consuming RHS) {
        self.lhs = lhs
        self.rhs = rhs
    }
    
    @usableFromInline
    typealias Element = LHS.Element
    
}


extension ConcurrentStream {
    
    // MARK: (lhs: some Error, rhs: some Error)
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
    /// ## Topics
    /// ### Variants
    /// These variants are implementation details, which are employed to ensure the proper throwing.
    /// - ``ConcurrentStream/+(_:_:)-25x9z``
    /// - ``ConcurrentStream/+(_:_:)-8aocz``
    /// - ``ConcurrentStream/+(_:_:)-4p98m``
    @inlinable
    public static func + (_ lhs: consuming Self, _ rhs: consuming some ConcurrentStream<Element, some Error>) -> some ConcurrentStream<Element, any Error> {
        ConcurrentSerializedStream(lhs: consume lhs, rhs: consume rhs)
    }
    
    // MARK: (lhs: some Error, rhs: Never)
    /// Creates a new stream by concatenating the elements of two streams.
    ///
    /// This is a variant of ``ConcurrentStream/+(_:_:)-7m6k2``
    @inlinable
    public static func + (_ lhs: consuming Self, _ rhs: consuming some ConcurrentStream<Element, Never>) -> some ConcurrentStream<Element, Failure> {
        ConcurrentSerializedStream(lhs: consume lhs, rhs: consume rhs)
    }

}


extension ConcurrentStream where Failure == Never {
    
    // MARK: (lhs: Never, rhs: some Error)
    /// Creates a new stream by concatenating the elements of two streams.
    ///
    /// This is a variant of ``ConcurrentStream/+(_:_:)-7m6k2``
    @inlinable
    public static func +<E> (_ lhs: consuming Self, _ rhs: consuming some ConcurrentStream<Element, E>) -> some ConcurrentStream<Element, E> where E: Error {
        ConcurrentSerializedStream(lhs: consume lhs, rhs: consume rhs)
    }
    
    // MARK: (lhs: some Error, rhs: Never)
    /// Creates a new stream by concatenating the elements of two streams.
    ///
    /// This is a variant of ``ConcurrentStream/+(_:_:)-7m6k2``
    @inlinable
    public static func + (_ lhs: consuming Self, _ rhs: consuming some ConcurrentStream<Element, Never>) -> some ConcurrentStream<Element, Never> {
        ConcurrentSerializedStream(lhs: consume lhs, rhs: consume rhs)
    }
    
}
