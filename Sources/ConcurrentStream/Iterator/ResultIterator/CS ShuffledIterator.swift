//
//  ConcurrentStreamShuffledIterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


@usableFromInline
internal final class ConcurrentStreamShuffledIterator<Stream>: ConcurrentStreamIterator where Stream: ConcurrentStream {
    
    private var base: AsyncThrowingStream<Word, any Error>.Iterator?
    
    private var task: Task<Void, any Error>?
    
    private var _block: Stream.SourceIterator
    
    @usableFromInline
    internal init(stream: Stream) async {
        self._block = stream.source
        self.base = AsyncThrowingStream(Word.self) { continuation in
            self.task = Task {
                do {
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        while let value = try await _block.next() {
                            group.addTask(priority: .medium) {
                                let next = try await stream.build(source: value)
                                continuation.yield(next)
                            }
                        }
                        
                        try await group.waitForAll()
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }.makeAsyncIterator()
    }
    
    /// Access the next element in the stream. `wait`ing is built-in.
    @usableFromInline
    internal func next() async throws -> Element? {
        do {
            try Task.checkCancellation()
            let next = try await base?.next()
            
            guard let next else { return nil }
            if let next {
                return next
            } else {
                return try await self.next()
            }

        } catch {
            self.cancel()
            throw error
        }
    }
    
    @usableFromInline
    internal func cancel() {
        task?.cancel()
        _block.cancel()
    }
    
    
    @usableFromInline
    internal typealias Element = Stream.Element
    
    /// The Internal stored word
    @usableFromInline
    internal typealias Word = Element?
    
}
