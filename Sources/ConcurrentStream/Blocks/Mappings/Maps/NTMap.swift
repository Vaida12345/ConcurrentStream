//
//  ConcurrentMapNonThrowingStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


private final class ConcurrentMapNonThrowingStream<Element, SourceStream>: ConcurrentStream where SourceStream: ConcurrentStream {
    
    /// The source stream
    private let source: SourceStream
    
    
    /// The iterator of `taskGroup`
    private var base: AsyncThrowingStream<Word, any Error>.Iterator?
    
    /// The buffer for retaining pending values.
    private var _buffer: Dictionary<Int, Element> = [:]
    
    /// The index for the next element to produce in `next()`
    private var index = 0
    
    /// The task containing the `TaskGroup`
    private var task: Task<Void, any Error>?
    
    
    
    fileprivate init(source: SourceStream, work: @Sendable @escaping (_: SourceStream.Element) async -> Element) async {
        self.source = source
        let (_stream, continuation) = AsyncThrowingStream.makeStream(of: Word.self)
        self.base = _stream.makeAsyncIterator()
        
        self.task = Task.detached { [weak self] in
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    var count = 0
                    while let value = try await source.next() {
                        let _count = count
                        
                        await Task.yield()
                        guard !Task.isCancelled else {
                            self?.cancel()
                            return
                        }
                        
//                        print("add task \(_count)")
                        group.addTask {
                            await Task.yield()
                            try Task.checkCancellation()
                            
                            let next = await (_count, work(value))
//                            print("finished \(_count)")
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
    }
    
    deinit {
        self.cancel()
    }
    
    /// Access the next element in the stream. `wait`ing is built-in.
    public func next() async throws(Failure) -> Element? {
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
            
            return value
        } catch {
            self.cancel()
            throw error as! Failure
        }
    }
    
    public func cancel() {
        task?.cancel()
        source.cancel()
    }
    
    /// The Internal stored word
    private typealias Word = (Int, Element)
    
    typealias Failure = SourceStream.Failure
    
}


extension ConcurrentStream {
    
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    ///
    /// The `taskGroup` is created and dispatched; this function returns immediately.
    ///
    /// - Parameters:
    ///   - transform: A mapping closure. `transform` accepts an element of this sequence as its parameter and returns a transformed value of the same or of a different type.
    ///
    /// - Complexity: The process entails creating a new `taskGroup`.
    ///
    /// - Throws: Sadly, there is no way to obtain the thrown error, even with typed throws.
    ///
    /// > Experiment:
    /// > There exists a ~3.6੫s overhead for each element. (Compared to ~500ps for each element of a sequence.)
    /// >
    /// > **The breakdown could be:**
    /// >
    /// > - Bridge from sequence to stream: ~320ns
    /// >
    /// > - Use of `AsyncStream`: ~1.6੫s
    /// >
    /// > - Use of `TaskGroup`: ~1.1੫s
    /// >
    /// > - Use of `Dictionary` as buffer: ~50ns
    /// >
    /// > *Please also note that this benchmark could be inaccuracy due to the nature of concurrency.*
    public consuming func map<T>(_ transform: @Sendable @escaping (Self.Element) async -> T) async -> some ConcurrentStream<T, Failure> {
        await ConcurrentMapNonThrowingStream(source: self, work: transform) // self cannot be consumed
    }
    
}
