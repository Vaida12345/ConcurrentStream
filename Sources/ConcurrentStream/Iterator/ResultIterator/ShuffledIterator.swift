//
//  ConcurrentStreamShuffledIterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

/*
internal final class ConcurrentStreamShuffledIterator<Stream>: ConcurrentStreamIterator where Stream: ConcurrentStream {
    
    
    /// The iterator of `taskGroup`
    private var base: AsyncThrowingStream<Word, any Error>.Iterator?
    
    /// The task containing the `TaskGroup`
    private var task: Task<Void, any Error>?
    
    /// The source iterator
    private let _block: Stream.SourceIterator
    
    
    internal init(stream: Stream) async {
        self._block = stream.source
        let (_stream, continuation) = AsyncThrowingStream.makeStream(of: Word.self)
        self.base = _stream.makeAsyncIterator()
        
        self.task = Task.detached { [weak self] in
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    while let value = try await self?._block.next() {
                        
                        await Task.yield()
                        guard !Task.isCancelled else {
                            self?.cancel()
                            return
                        }
                        
                        group.addTask {
                            await Task.yield()
                            try Task.checkCancellation()
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
    }
    
    deinit {
        self.cancel()
    }
    
    /// Access the next element in the stream. `wait`ing is built-in.
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
    
    internal func cancel() {
        task?.cancel()
        _block.cancel()
    }
    
    
    internal typealias Element = Stream.Element
    
    /// The Internal stored word
    private typealias Word = Element?
    
    
}
*/
