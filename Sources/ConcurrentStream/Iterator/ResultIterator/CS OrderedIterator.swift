//
//  ConcurrentStreamOrderedIterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


/// Using `ConcurrentStreamOrderedIterator`, which is the default ordered iterator, as an example.
///
/// ### Initialization
///
/// In the initialization phase, a `taskGroup` is created and detached. The results of the `taskGroup` is reported using an `AsyncStream` continuation.
///
/// Multiple `yield` and cancelation checking points were created throughout the creation and execution of the child tasks of `taskGroup`. Using the following code,
/// ```swift
/// var iterator = await ConcurrentStreamOrderedIterator(stream: stream)
///
/// while let next = try await iterator.next() {
///     print(">>", next)
/// }
/// ```
/// You can see a recurring sequence where a task is *created*, *executed*, and *reported* for each child. This means that typically, the report for the previous child comes before the creation of the next child task. You will also observe that the sequence occurs in batches, matching the number of cores with which a computer is equipped.
///
/// ### The Order
///
/// The sequence in which results are yielded upon invoking `next` corresponds to the sequence in the originating `stream`. The implementation entails the use of a dictionary buffer, which retains any pending values until the targeted value is generated.
///
/// ### Cancellation
///
/// As a `taskGroup` waits for all of its child tasks to complete before returning, the `taskGroup` used in the iterator is detached. Hence manual task cancelation is required.
///
/// - Note: The iterator of the source `stream` would also require manual cancelation. This iterator is called in the `taskGroup` in sequence to produce the next source.
///
/// The tasks can be cancelled in three ways.
/// - Releasing reference to the iterator. (Cancelation in `deinit`)
/// - Automatically cancelled when the parent `Task` executing the `next` method is cancelled.
/// - Calling ``ConcurrentStreamIterator/cancel()`` explicitly.
///
/// This should cover the common use case. In the following example, the stream is canceled due to the release of its reference, caused by the exit of the function, which in turn is triggered by the thrown error.
/// ```swift
/// var iterator = await ConcurrentStreamOrderedIterator(stream: stream)
///
/// for _ in 0...1000 {
///     try Task.checkCancellation()
///     heavyWork(i: 0)
/// }
/// ```
///
/// As another example, the cancellation of the stream occurs while awaiting the retrieval of the `next` element.
/// ```swift
/// var iterator = await ConcurrentStreamOrderedIterator(stream: stream)
///
/// while let next = try await iterator.next() {
///     ...
/// }
@usableFromInline
internal final class ConcurrentStreamOrderedIterator<Stream>: ConcurrentStreamIterator where Stream: ConcurrentStream {
    
    /// The iterator of `taskGroup`
    private var base: AsyncThrowingStream<Word, any Error>.Iterator?
    
    /// The buffer for retaining pending values.
    private var _buffer: Dictionary<Int, Element?> = [:]
    
    /// The index for the next element to produce in `next()`
    private var index = 0
    
    /// The task containing the `TaskGroup`
    private var task: Task<Void, any Error>?
    
    /// The source iterator
    private var _block: Stream.SourceIterator
    
    
    @usableFromInline
    internal init(stream: Stream) async {
        self._block = stream.source
        let (_stream, continuation) = AsyncThrowingStream.makeStream(of: Word.self)
        self.base = _stream.makeAsyncIterator()
        
        self.task = Task.detached { [weak self] in
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    var count = 0
                    while let value = try await self?._block.next() {
                        let _count = count
                        print("getting next: \(_count) isCancelled: \(Task.isCancelled)")
                        
                        await Task.yield()
                        guard !Task.isCancelled else {
                            print("cancelled")
                            self?.cancel()
                            return
                        }
                        
                        group.addTask {
                            await Task.yield()
                            try Task.checkCancellation()
                            let next = try await (_count, stream.build(source: value))
                            print("produced \(next.0)")
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
        print("deinit")
        self.cancel()
    }
    
    /// Access the next element in the stream. `wait`ing is built-in.
    @usableFromInline
    internal func next() async throws -> Element? {
        do {
            let index = index
            while _buffer[index] == nil {
                await Task.yield()
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
            print("will cancel")
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
