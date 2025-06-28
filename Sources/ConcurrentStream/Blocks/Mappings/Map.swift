//
//  ConcurrentMapStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


/// The primary associative values are: The returned element, The source stream, the error that this stream throws, the error that the work closure throws.
@usableFromInline
final class ConcurrentMapStream<Element, SourceStream, Failure, TransformFailure>: ConcurrentStream where SourceStream: ConcurrentStream, TransformFailure: Error, Failure: Error, Element: Sendable {
    
    /// The source stream cancelable
    @usableFromInline
    let parentCancelable: @Sendable () -> Void
    
    /// The continuation of AsyncThrowingStream, used for cancelation.
    @usableFromInline
    let continuation: AsyncThrowingStream<Word, any Error>.Continuation
    
    
    /// The iterator of `taskGroup`
    @usableFromInline
    var base: AsyncThrowingStream<Word, any Error>.Iterator?
    
    @usableFromInline
    let store = Store()
    
    /// The task containing the `TaskGroup`
    @usableFromInline
    var task: Task<Void, any Error>?
    
    
    @inlinable
    init(source: consuming sending SourceStream, work: @Sendable @escaping @isolated(any) (_: SourceStream.Element) async throws(TransformFailure) -> Element) async {
        self.parentCancelable = source.cancel
        let (_stream, continuation) = AsyncThrowingStream.makeStream(of: Word.self)
        self.base = _stream.makeAsyncIterator()
        self.continuation = continuation
        
        self.task = Task.detached { [_cancel = self.cancel] in
            do {
                try await withThrowingDiscardingTaskGroup { group in
                    var count = 0
                    while let value = try await source.next() {
                        let _count = count
                        
                        await Task.yield()
                        
                        guard group.addTaskUnlessCancelled(priority: nil, operation: {
                            await Task.yield()
                            try Task.checkCancellation()
                            
                            do {
                                let next = try await (_count, work(value))
                                continuation.yield(next)
                            } catch {
                                continuation.finish(throwing: error)
                                _cancel() // finish before cancel, otherwise `_cancel` would call `continuation.finish` again.
                            }
                        }) else { throw CancellationError() }
                        
                        count &+= 1
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
                _cancel() // finish before cancel, otherwise `_cancel` would call `continuation.finish` again.
            }
        }
    }
    
    @inlinable
    deinit {
        self.cancel()
    }
    
    /// Access the next element in the stream. `wait`ing is built-in.
    @inlinable
    func next() async throws(Failure) -> Element? {
        do {
            while await store.currentIndexIsMissing {
                try Task.checkCancellation()
                
                guard let word = try await base?.next() else {
                    return nil
                } // the only place where `nil` is returned, other than `CancellationError`.
                
                await store.updateValue(word.1, forKey: word.0)
            }
            
            let removed = await self.store.removeValue()
            await self.store.increment()
            
            return removed
        } catch is CancellationError {
            self.cancel()
            return nil
        } catch {
            self.cancel()
            throw error as! Failure
        }
    }
    
    @inlinable
    nonisolated var cancel: @Sendable () -> Void {
        { [_taskCancel = self.task?.cancel, _cancel = parentCancelable, _finish = continuation.finish] in
            _taskCancel?()
            _cancel()
            _finish(CancellationError())
        }
    }
    
    /// The Internal stored word
    @usableFromInline
    typealias Word = (Int, Element)
    
    @usableFromInline
    actor Store {
        
        /// The buffer for retaining pending values.
        @usableFromInline
        var buffer: [Int : Element] = [:]
        
        /// The index for the next element to produce in `next()`
        @usableFromInline
        var index = 0
        
        @inlinable
        var currentIndexIsMissing: Bool {
            self.buffer[self.index] == nil
        }
        
        @inlinable
        func updateValue(_ value: Element, forKey key: Int) {
            self.buffer.updateValue(value, forKey: key)
        }
        
        @inlinable
        func removeValue() -> Element? {
            self.buffer.removeValue(forKey: self.index)
        }
        
        @inlinable
        func increment() {
            self.index += 1
        }
        
    }
    
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
    /// > *Please also note that this benchmark could be inaccurate due to the nature of concurrency.*
    ///
    /// - Note: With `Synchronization`, the `next` method can be safely evoked in any thread.
    ///
    /// ## Topics
    /// ### Variants
    /// These variants are implementation details, which are employed to ensure the proper throwing.
    ///
    /// - ``ConcurrentStream/map(_:)-o7b9``
    /// - ``ConcurrentStream/map(_:)-4rkgy``
    /// - ``ConcurrentStream/map(_:)-8qjns``
    @inlinable
    public consuming func map<T, E>(_ transform: @Sendable @escaping (Self.Element) async throws(E) -> T) async -> some ConcurrentStream<T, any Error> where T: Sendable, E: Error {
        await ConcurrentMapStream<T, Self, any Error, E>(source: self, work: transform) // self cannot be consumed
    }
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: Never)
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/map(_:)-4q8b6``
    @inlinable
    public consuming func map<T>(_ transform: @Sendable @escaping (Self.Element) async -> T) async -> some ConcurrentStream<T, Failure> where T: Sendable {
        await ConcurrentMapStream<T, Self, Failure, Never>(source: self, work: transform) // self cannot be consumed
    }
    
}



extension ConcurrentStream where Failure == Never {
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: some Error)
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/map(_:)-4q8b6``
    @inlinable
    public consuming func map<T, E>(_ transform: @Sendable @escaping (Self.Element) async throws(E) -> T) async -> some ConcurrentStream<T, E> where T: Sendable, E: Error {
        await ConcurrentMapStream<T, Self, E, E>(source: self, work: transform)
    }
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: Never)
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    ///
    /// This is a variant of ``ConcurrentStream/map(_:)-4q8b6``
    @inlinable
    public consuming func map<T>(_ transform: @Sendable @escaping (Self.Element) async -> T) async -> some ConcurrentStream<T, Never> where T: Sendable, Failure == Never {
        await ConcurrentMapStream(source: self, work: transform) // self cannot be consumed
    }
    
}
