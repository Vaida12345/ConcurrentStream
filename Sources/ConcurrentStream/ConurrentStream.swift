//
//  ConcurrentStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//



/// A stream, where each block works concurrently if possible.
///
/// ## Overview
///
/// The ``ConcurrentStream`` aims to combine the functionality of execution in parallel and `AsyncSequence`.
///
/// ```swift
/// let stream = (1...100).stream.map(heavyWork)
///
/// while let next = try await stream.next() {
///     ...
/// }
/// ```
/// The `heavyWork`s are executed in parallel, while the completed ones are reported in order.
///
/// - Creation of a stream dispatches the work and returns immediately.
/// - ``ConcurrentStream/next()`` would wait for the work to complete.
///
/// - Warning: A stream is fragile, elements are discarded during traversal. Hence do never reuse a stream.
///
/// ### Usage
///
/// A stream can be created using `.stream` on a `Sequence` or an `AsyncSequence`.
///
/// ```swift
/// try await (1...1000)
///     .stream
///     .map { $0 % 2 }
/// ```
///
/// ### Cancelation
///
/// The stream can be cancelled in three ways.
/// - Releasing reference to the `stream`. (Cancelation in `deinit`)
/// - Automatically cancelled when the parent `Task` executing  ``ConcurrentStream/next()`` is cancelled.
/// - Calling ``ConcurrentStream/cancel`` explicitly.
///
/// This should cover the common use case. You can read more in ``ConcurrentStream/cancel``.
///
/// ### Overhead
///
/// There are generally two kinds of operations:
///
/// - ``map(_:)-4q8b6``-like, where a `taskGroup` is created and dispatched upon invocation.
/// - ``compacted()``-like, where a `taskGroup` is not generated. These operations are lightweight and do not involve additional overhead associated with being `async`.
///
/// In the first scenario, unavoidable overhead arises from the use of `AsyncStream` to capture the results of the `taskGroup` and the `taskGroup` itself. Therefore, it is advisable to minimize the number of `map`-like operations queued.
///
/// - Warning: All methods that take a closure as an argument will create `taskGroup`s to execute the closure.
/// - Tip: You can determine if a `taskGroup` has been instantiated (thereby causing significant overhead) by examining the function signature. It is necessary to use `await` on methods where a `taskGroup` is created; conversely, `await` is not required when a `taskGroup` has not been instantiated.
///
///
/// ## Implementation Notes
/// ### Class Protocol
///
/// This protocol is a class protocol, due to the fact that
/// - A class protocol has a `deinit` block, where the task can be cancelled.
/// - A class protocol has non-next, making the following way of cancelation possible:
/// ```swift
/// let stream = some ConcurrentStream
/// let cancel = stream.cancel
///
/// try await withTaskCancellationHandler {
///     ...
///     stream.foo()
/// } onCancel: {
///     cancel() // the nonisolated cancel
/// }
/// ```
///
/// ### The order
/// A stream is always ordered, given the negligible performance difference between an ordered iterator and an unordered one.
///
///
/// ## Throwing
///
/// In ``map(_:)-4q8b6``-like closure, it should only throw when one needs to cancel the pending operations and throw the error, which will be captured in
///
/// ```swift
/// while let next = try await stream.next
/// ```
///
/// Otherwise, returns a `nil` would be a better choice, allowing the stream to keep reporting the valid outputs.
///
///
/// ### rethrows implementation
///
/// With typed throws, ``ConcurrentStream`` now only throws when it is required to.
///
/// > Example:
///     > The following will no longer throw in the latest implementations.
/// >
/// > ```swift
/// > await (1...1000)
/// >     .stream
/// >     .map { $0 % 2 }
/// >     .sequence
/// > ```
///
///
/// ## Topics
///
/// ### Creation of stream
/// The ``ConcurrentStream`` does not offer a direct way of creation. You would always need to bridge from other structures.
///
/// - ``Swift/Sequence/stream``
///
/// ### Obtaining elements explicitly
/// Returns the next element in the iterator. The elements will always be returned in the order they were submitted.
/// - ``next()``
/// - ``forEach(_:)``
///
/// ### Converting stream
/// - ``sequence``
/// - ``async``
///
///
/// ### Cancelling stream
///
/// This is the explicit way of canceling a stream. A stream would be canceled explicitly when the reference is released and when the parent `Task` is cancelled.
///
/// - ``cancel``
///
///
/// ### Lightweight Operations
/// These operations are lightweight and do not involve additional overhead associated with being `ConcurrentStream`. This is also indicated by the lack of `await` in the function call.
///
/// - ``compacted()``
/// - ``unique()``
/// - ``flatten()-3mp1s``
/// - ``+(_:_:)-7m6k2``
///
///
/// ### Mappings
/// These operations involve creation of `taskGroup` in each function call.
///
/// - ``map(_:)-4q8b6``
/// - ``compactMap(_:)-8yxjm``
/// - ``flatMap(_:)-6o6er``
///
///
/// ### Excluding Elements
/// Note that there is no way to retrieve the excluded elements. These operation themselves are lightweight.
///
/// - ``filter(_:)-5v6w8``
public protocol ConcurrentStream<Element, Failure>: Sendable {
    
    /// Returns the next element in the iterator.
    ///
    /// The elements will always be returned in the order they were submitted.
    ///
    /// It is a programmer error to invoke `next()` from a concurrent context that contends with another such call, which results in a call to `fatalError()`. This is a constrain from `AsyncThrowingStream.Iterator`.
    ///
    /// - Returns: The next element in the iterator, `nil` when reached the end.
    func next() async throws(Failure) -> sending Self.Element?
    
    /// Cancels the stream, and its upstreams.
    ///
    /// As a `taskGroup` waits for all of its child tasks to complete before returning, the `taskGroup` used in the iterator is detached. Hence manual task cancelation is required.
    ///
    /// - Note: Due to the nature of concurrency, if the closure does not implement checking cancelation, the submitted tasks to ``ConcurrentStream/map(_:)-4q8b6``-like streams cannot be cancelled until these closure finish.
    ///
    /// ### Conditions
    ///
    /// The tasks can be cancelled in three ways.
    /// - Releasing reference to the `stream`. (Cancelation in `deinit`)
    /// - Automatically cancelled when the parent `Task` executing  ``ConcurrentStream/next()`` is cancelled.
    /// - Calling ``ConcurrentStream/cancel`` explicitly.
    ///
    /// The task is also cancelled automatically when:
    /// - An error is thrown in the closure (``ConcurrentStream/map(_:)-4q8b6``-like).
    /// - Child streams are cancelled. (Note: This only goes up, not down)
    /// - Task is cancelled during a bridge method, such as ``ConcurrentStream/sequence``. With the exception of ``ConcurrentStream/async``, which must be cancelled manually.
    ///
    /// ### Behaviors
    ///
    /// After the task is cancelled, successive calls to ``ConcurrentStream/next()`` depends on its origin. The stream itself does not store the state of whether it has been cancelled.
    /// - If it does not evolve ``ConcurrentStream/map(_:)-4q8b6``-like: The method is unaffected, why would it be?
    /// - Otherwise this method would return anything left in the buffer, and `nil` in subsequence calls.
    ///
    /// ### Use cases
    ///
    /// This should cover the common use case. In the following example, the stream is canceled immediately due to the release of its reference, caused by the exit of the function.
    /// ```swift
    /// Task {
    ///     let stream = (1...10).stream.map { $0 }
    /// }
    /// ```
    ///
    /// One could also use the `withTaskCancellationHandler` call,
    ///
    /// ```swift
    /// let stream = some ConcurrentStream
    ///
    /// try await withTaskCancellationHandler {
    ///     ...
    /// } onCancel: {
    ///     stream.cancel()
    /// }
    /// ```
    ///
    /// This is only required when you **do not** interact with the stream in any way. This cannot be done automatically due to the nature of `ConcurrentStream`: The initializer block returns immediately and dispatches the task. The child-generating task is then run on a different task group, independent of the original one.
    ///
    /// As another example, the cancellation of the stream occurs while awaiting the retrieval of the `next` element.
    /// ```swift
    /// var iterator = await ConcurrentStreamOrderedIterator(stream: stream)
    ///
    /// while let next = try await iterator.next() {
    ///     ...
    /// }
    /// ```
    ///
    /// - Tip: With `Swift6.0`, this method is now declared as a property. Nevertheless, you are recommended to use this as a function.
    nonisolated var cancel: @Sendable () -> Void { get }
    
    /// The type of element produced by this stream.
    associatedtype Element
    
    /// The type of error produced by this stream.
    associatedtype Failure: Error
    
}
