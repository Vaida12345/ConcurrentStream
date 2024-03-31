//
//  AsyncConcurrentStreamSequence.swift
//
//
//  Created by Vaida on 2024/3/31.
//


public struct AsyncConcurrentStreamSequence<SourceStream>: AsyncSequence where SourceStream: ConcurrentStream {
    
    private let source: SourceStream
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(source: source)
    }
    
    fileprivate init(source: SourceStream) {
        self.source = source
    }
    
    
    public struct AsyncIterator: AsyncIteratorProtocol {
        
        private let source: SourceStream
        
        fileprivate init(source: SourceStream) {
            self.source = source
        }
        
        public func next() async throws -> Element? {
            try await source.next()
        }
        
    }
    
    public typealias Element = SourceStream.Element
    
}



extension ConcurrentStream {
    
    /// Converts the stream to an `AsyncSequence`.
    ///
    /// - Warning: Unlike typically `AsyncSequence`, you should never reuse the returned sequence.
    ///
    /// - Complexity: O(*1*), Work is dispatched on return.
    ///
    /// ## Topics
    /// ### The Structure
    /// - ``AsyncConcurrentStreamSequence``
    public var async: AsyncConcurrentStreamSequence<Self> {
        consuming get {
            AsyncConcurrentStreamSequence(source: self)
        }
    }
    
}
