//
//  AsyncConcurrentStreamSequence.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 2024/3/31.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


/// An `AsyncSequence` bridged from ``ConcurrentStream``.
///
/// You can use ``cancel`` to cancel the underlying `stream`. For more information, see ``cancel``.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
public final class AsyncConcurrentStreamSequence<SourceStream>: AsyncSequence where SourceStream: ConcurrentStream {
    
    @usableFromInline
    let source: SourceStream
    
    /// Creates the iterator.
    ///
    /// - Warning: Similar to `taskGroup`, you should only call this function once, either explicitly or implicitly.
    @inlinable
    public consuming func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(source: source)
    }
    
    @inlinable
    public init(source: consuming SourceStream) {
        self.source = source
    }
    
    
    /// Cancels the upstreams of this async sequence.
    ///
    /// After bridging a `stream` to a `AsyncSequence`, the ways in which the `stream` can be cancelled is reduced. Nevertheless, the underlying stream can be cancelled in the following ways.
    /// - Releasing reference to the `AsyncSequence`. (Cancellation in `deinit`)
    /// - Calling this method explicitly.
    ///
    /// If the this sequence is once again transform into another `AsyncSequence`. You could only rely on the error thrown on task cancelation. After the error is thrown, the contents in the closure is released, calling cancellation in `deinit`.
    @inlinable
    public nonisolated var cancel: @Sendable () -> Void {
        { [_cancel = source.cancel] in
            _cancel()
        }
    }
    
    
    public final class AsyncIterator: AsyncIteratorProtocol {
        
        @usableFromInline
        let source: SourceStream
        
        @inlinable
        init(source: consuming SourceStream) {
            self.source = source
        }
        
        @inlinable
        public func next() async throws(SourceStream.Failure) -> Element? {
            do {
                return try await source.next()
            } catch {
                throw error
            }
        }
        
        public typealias Failure = SourceStream.Failure
        
    }
    
    public typealias Element = SourceStream.Element
    
}



extension ConcurrentStream {
    
    /// Converts the stream to an `AsyncSequence`.
    ///
    /// - Warning: Similar to `taskGroup`, you should never reuse the returned sequence.
    ///
    /// ### Cancelation
    ///
    /// After bridging a `stream` to a `AsyncSequence`, the ways in which the `stream` can be cancelled is reduced. Nevertheless, the underlying stream can be cancelled in the following ways.
    /// - Releasing reference to the `AsyncSequence`. (Cancelation in `deinit`)
    /// - Calling this method explicitly.
    ///
    /// If the this sequence is once again transform into another `AsyncSequence`. You could only rely on the error thrown on task cancelation. After the error is thrown, the contents in the closure is released, calling cancellation in `deinit`.
    ///
    /// - Complexity: O(*1*), Work is dispatched on return.
    ///
    /// ## Topics
    /// ### The Structure
    /// - ``AsyncConcurrentStreamSequence``
    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
    @inlinable
    public var async: AsyncConcurrentStreamSequence<Self> {
        consuming get {
            AsyncConcurrentStreamSequence(source: consume self)
        }
    }
    
}
