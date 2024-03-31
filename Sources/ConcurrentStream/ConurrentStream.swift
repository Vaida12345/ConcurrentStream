//
//  ConcurrentStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


// Documentation in DocC.
@rethrows
public protocol ConcurrentStream<Element>: AsyncIteratorProtocol, AnyObject {
    
    /// Returns the next element in the iterator.
    ///
    /// The elements will always be returned in the order they were submitted.
    ///
    /// - Returns: The next element in the iterator, `nil` when reached the end.
    func next() async throws -> Element?
    
    /// Cancels the stream, and its upstreams.
    ///
    /// The stream can be cancelled in three ways.
    /// - Releasing reference to the `stream`. (Cancelation in `deinit`)
    /// - Automatically cancelled when the parent `Task` executing  ``ConcurrentStream/ConcurrentStream/next()`` is cancelled.
    /// - Calling ``ConcurrentStream/ConcurrentStream/cancel()`` explicitly.
    ///
    /// This should cover the common use case. You can read details about the `ConcurrentStream` [here](<doc:Principle>).
    ///
    /// > Example:
    /// > You could use the `withTaskCancellationHandler` to observe the cancelation of parent task,
    /// >
    /// > ```swift
    /// > let stream = some ConcurrentStream
    /// >
    /// > try await withTaskCancellationHandler {
    /// >     ...
    /// >     stream.foo()
    /// > } onCancel: {
    /// >     iterator.cancel()
    /// > }
    /// > ```
    func cancel()
    
    /// The type of element produced by this stream.
    associatedtype Element
    
}
