//
//  ConcurrentStreamOrderedIterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


import OSLog


@usableFromInline
internal final class ConcurrentStreamOrderedIterator<Stream>: ConcurrentStreamIterator where Stream: ConcurrentStream {
    
    private var base: AsyncThrowingStream<Word, any Error>.Iterator?
    
    private var _buffer: Dictionary<Int, Element?> = [:]
    
    private var index = 0
    
    private var task: Task<Void, any Error>?
    
    private var _block: Stream.SourceIterator
    
    @usableFromInline
    var isRawIterator: Bool { true }
    
    
    @usableFromInline
    internal init(stream: Stream) async {
        self._block = stream.source
        self.base = AsyncThrowingStream(Word.self) { continuation in
            self.task = Task {
                do {
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        var count = 0
                        while let value = try await _block.next() {
                            let _count = count
                            
                            group.addTask(priority: .medium) {
                                let next = try await (_count, stream.build(source: value))
                                continuation.yield(next)
                            }
                            
                            count &+= 1
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
            let index = index
            while _buffer[index] == nil {
                try Task.checkCancellation()
                guard let word = try await base?.next() else {
                    return nil
                } // the only place where `nil` is returned.
                
                _buffer.updateValue(word.1, forKey: word.0)
            }
            
            let value = _buffer.removeValue(forKey: index)!
            self.index += 1
            
            if let value {
                return value // return the element
            } else {
                // no element here, caused by the block building it, not by waiting.
                return try await next() // get next element
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
    internal typealias Word = (Int, Element?)
    
}
