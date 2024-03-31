//
//  ConcurrentFlattenStream.swift
//
//
//  Created by Vaida on 2024/3/31.
//


fileprivate final class ConcurrentFlattenStream<SourceStream>: ConcurrentStream where SourceStream: ConcurrentStream, SourceStream.Element: ConcurrentStream {
    
    /// The source stream
    private let source: SourceStream
    
    /// The current iterating child of `source`.
    private var stream: SourceStream.Element? = nil
    
    fileprivate init(source: SourceStream) {
        self.source = source
    }
    
    func next() async throws -> Element? {
        if let next = try await stream?.next() {
            return next
        }
        
        // the current stream is drain, get next one
        guard let nextStream = try await source.next() else {
            // no next stream, exit
            return nil
        }
        
        self.stream = nextStream
        return try await self.next()
    }
    
    func cancel() {
        self.source.cancel()
    }
    
    typealias Element = SourceStream.Element.Element
    
}


extension ConcurrentStream {
    
    /// Returns a compact mapped stream.
    ///
    /// The overhead of this method is kept minimum. It would perform the same as `Sequence.flatten()`.
    ///
    /// - Complexity: This method does not involve the creation of a new `taskGroup`.
    public consuming func flatten<T>() -> some ConcurrentStream<T> where Element: ConcurrentStream<T> {
        ConcurrentFlattenStream(source: self)
    }
    
}
