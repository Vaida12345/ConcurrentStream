//
//  ConcurrentMapStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


/// The primary associative values are: The returned element, The source stream, the error that this stream throws, the error that the work closure throws.
fileprivate final class ConcurrentMapStream<Element, SourceStream, Failure, TransformFailure>: ConcurrentStream where SourceStream: ConcurrentStream, TransformFailure: Error, Failure: Error {
    
    /// The source stream
    private let source: SourceStream
    
    /// The continuation of AsyncThrowingStream, used for cancelation.
    private let continuation: AsyncThrowingStream<Word, any Error>.Continuation
    
    
    /// The iterator of `taskGroup`
    private var base: AsyncThrowingStream<Word, any Error>.Iterator?
    
    /// The buffer for retaining pending values.
    private var _buffer: Dictionary<Int, Element> = [:]
    
    /// The index for the next element to produce in `next()`
    private var index = 0
    
    /// The task containing the `TaskGroup`
    private var task: Task<Void, any Error>?
    
    
    
    init(source: SourceStream, work: @Sendable @escaping (_: SourceStream.Element) async throws(TransformFailure) -> Element) async {
        nonisolated(unsafe)
        let source = consume source
        self.source = source
        let (_stream, continuation) = AsyncThrowingStream.makeStream(of: Word.self)
        self.base = _stream.makeAsyncIterator()
        self.continuation = continuation
        
        self.task = Task.detached { [_cancel = self.cancel] in
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    var count = 0
                    while let value = try await source.next() {
                        let _count = count
                        nonisolated(unsafe) // Nonisolated as I do not want to restrain `Element` to `Sendable` for now.
                        let value = value
                        
                        await Task.yield()
                        
                        guard group.addTaskUnlessCancelled(priority: nil, operation: {
                            await Task.yield()
                            try Task.checkCancellation()
                            
                            let next = try await (_count, work(value))
                            continuation.yield(next)
                        }) else { throw CancellationError() }
                        
                        count &+= 1
                    }
                    
                    try await group.waitForAll()
                    continuation.finish()
                }
            } catch {
                continuation.finish(throwing: error)
                _cancel() // finish before cancel, otherwise `_cancel` would call `continuation.finish` again.
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
                } // the only place where `nil` is returned, other than `CancellationError`.
                
                _buffer.updateValue(word.1, forKey: word.0)
            }
            
            let value = _buffer.removeValue(forKey: index)!
            self.index += 1
            
            return value
        } catch is CancellationError {
            self.cancel()
            return nil
        } catch {
            self.cancel()
            throw error as! Failure
        }
    }
    
    public nonisolated var cancel: @Sendable () -> Void {
        { [_taskCancel = self.task?.cancel, _cancel = source.cancel, _finish = continuation.finish] in
            _taskCancel?()
            _cancel()
            _finish(CancellationError())
        }
    }
    
    /// The Internal stored word
    private typealias Word = (Int, Element)
    
}


extension ConcurrentStream {
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: some Error)
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    ///
    /// The `taskGroup` is created and dispatched; this function returns immediately.
    ///
    /// - Parameters:
    ///   - transform: A mapping closure. `transform` accepts an element of this sequence as its parameter and returns a transformed value of the same or of a different type.
    ///
    /// - Complexity: The process entails creating a new `taskGroup`.
    ///
    /// - Returns: The resulting stream also returns `nil` when the task is cancelled. (Instead of throwing `CancelationError`.)
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
    ///
    /// ## Topics
    /// ### Variants
    /// These variants are implementation details, which are employed to ensure the proper throwing.
    ///
    /// - ``ConcurrentStream/map(_:)-o7b9``
    /// - ``ConcurrentStream/map(_:)-4rkgy``
    /// - ``ConcurrentStream/map(_:)-8qjns``
    public consuming func map<T, E>(_ transform: @Sendable @escaping (Self.Element) async throws(E) -> T) async -> some ConcurrentStream<T, any Error> where E: Error {
        await ConcurrentMapStream<T, Self, any Error, E>(source: self, work: transform) // self cannot be consumed
    }
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: Never)
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/map(_:)-4q8b6``
    public consuming func map<T>(_ transform: @Sendable @escaping (Self.Element) async -> T) async -> some ConcurrentStream<T, Failure> {
        await ConcurrentMapStream<T, Self, Failure, Never>(source: self, work: transform) // self cannot be consumed
    }
    
}



extension ConcurrentStream where Failure == Never {
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: some Error)
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/map(_:)-4q8b6``
    public consuming func map<T, E>(_ transform: @Sendable @escaping (Self.Element) async throws(E) -> T) async -> some ConcurrentStream<T, E> where E: Error {
        await ConcurrentMapStream<T, Self, E, E>(source: self, work: transform)
    }
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: Never)
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/map(_:)-4q8b6``
    public consuming func map<T>(_ transform: @Sendable @escaping (Self.Element) async -> T) async -> some ConcurrentStream<T, Never> where Failure == Never {
        await ConcurrentMapStream(source: self, work: transform) // self cannot be consumed
    }
    
}
