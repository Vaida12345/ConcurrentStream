//
//  ConcurrentMapStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

import Synchronization


/// The primary associative values are: The returned element, The source stream, the error that this stream throws, the error that the work closure throws.
@usableFromInline
final class ConcurrentMapStream<Element, SourceStream, Failure, TransformFailure>: ConcurrentStream where SourceStream: ConcurrentStream, TransformFailure: Error, Failure: Error {

    /// The source stream cancelable
    @usableFromInline
    let parentCancelable: @Sendable () -> Void

    /// The continuation of AsyncThrowingStream, used for cancelation.
    @usableFromInline
    let continuation: AsyncThrowingStream<Word, any Error>.Continuation


    @usableFromInline
    let store: Store

    /// The task containing the `TaskGroup`
    @usableFromInline
    let task: Task<Void, any Error>

    /// The iterator of `taskGroup`
    @usableFromInline
    nonisolated(unsafe) var iterator: AsyncThrowingStream<Word, any Error>.Iterator


    @inlinable
    init(name: String? = nil, source: consuming sending SourceStream, work: @Sendable @escaping (_: SourceStream.Element) async throws(TransformFailure) -> sending Element) async {
        self.parentCancelable = source.cancel
        let (_stream, continuation) = AsyncThrowingStream.makeStream(of: Word.self)
        self.store = Store()
        self.iterator = _stream.makeAsyncIterator()
        self.continuation = continuation

        self.task = Task.detached { [parentCancelable = source.cancel] in
            do {
                try await withThrowingDiscardingTaskGroup { group in
                    var count = 0
                    while let value = try await source.next() {
                        let _count = count

                        await Task.yield()

                        guard group.addTaskUnlessCancelled(name: name, priority: nil, operation: {
                            await Task.yield()
                            try Task.checkCancellation()

                            do {
                                let result = try await work(value)
                                continuation.yield(Word(_count, result))
                            } catch {
                                continuation.finish(throwing: error)
                                parentCancelable() // throwing will stop the task.
                            }
                        }) else { throw CancellationError() }

                        count &+= 1
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
                parentCancelable()
            }
        }
    }

    @inlinable
    deinit {
        self.cancel()
    }

    /// Access the next element in the stream. `wait`ing is built-in.
    @inlinable
    func next() async throws(Failure) -> sending Element? {
        do {
            while store.currentIndexIsMissing {
                try Task.checkCancellation()

                let word = try await self.iterator.next()
                guard let word else { return nil }
                store.insert(word)
            }

            let removed = store.removeValue()
            store.increment()

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
        { [_taskCancel = self.task.cancel, _cancel = parentCancelable, _finish = continuation.finish] in
            _taskCancel()
            _cancel()
            _finish(CancellationError())
        }
    }

    /// The Internal stored word
    @usableFromInline
    typealias Word = (Int, Element)

    @usableFromInline
    final class Store: @unchecked Sendable {

        @usableFromInline
        let _lock = Mutex<(buffer: [Int : Element], index: Int)>((buffer: [:], index: 0))

        @inlinable
        init() { }

        @inlinable
        var currentIndexIsMissing: Bool {
            _lock.withLock { $0.buffer[$0.index] == nil }
        }

        @inlinable
        func insert(_ word: Word) {
            _lock.withLock { _ = $0.buffer.updateValue(word.1, forKey: word.0) }
        }

        @inlinable
        func removeValue() -> Element? {
            _lock.withLock {
                // This is safe, as `self` no longer has access to `removed`.
                nonisolated(unsafe) let removed = $0.buffer.removeValue(forKey: $0.index)
                return removed
            }
        }

        @inlinable
        func increment() {
            _lock.withLock { $0.index += 1 }
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
    @inlinable
    public consuming func map<T, E>(name: String? = nil, _ transform: @Sendable @escaping (Self.Element) async throws(E) -> sending T) async -> some ConcurrentStream<T, any Error> where E: Error {
        await ConcurrentMapStream<T, Self, any Error, E>(name: name, source: self, work: transform) // self cannot be consumed
    }
    
    // MARK: (SourceStream.Failure: some Error, TransformFailure: Never)
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    @inlinable
    public consuming func map<T>(name: String? = nil, _ transform: @Sendable @escaping (Self.Element) async -> sending T) async -> some ConcurrentStream<T, Failure> {
        await ConcurrentMapStream<T, Self, Failure, Never>(name: name, source: self, work: transform) // self cannot be consumed
    }
    
}



extension ConcurrentStream where Failure == Never {
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: some Error)
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    @inlinable
    public consuming func map<T, E>(name: String? = nil, _ transform: @Sendable @escaping (Self.Element) async throws(E) -> sending T) async -> some ConcurrentStream<T, E> where E: Error {
        await ConcurrentMapStream<T, Self, E, E>(name: name, source: self, work: transform)
    }
    
    // MARK: (SourceStream.Failure: Never, TransformFailure: Never)
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    @inlinable
    public consuming func map<T>(name: String? = nil, _ transform: @Sendable @escaping (Self.Element) async -> sending T) async -> some ConcurrentStream<T, Never> where Failure == Never {
        await ConcurrentMapStream(name: name, source: self, work: transform) // self cannot be consumed
    }
    
}
