//
//  ConcurrentStream Extensions.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


extension ConcurrentStream {
    
    /// Converts the stream to an `Array`.
    ///
    /// - returns: The returned `sequence` is in the same order as the input. The returned array is populated on return.
    ///
    /// - Complexity: O(*n*).
    @inlinable
    public var sequence: Array<Element> {
        consuming get async throws(Failure) {
            let stream = consume self
            let _cancel = stream.cancel
            
            do {
                return try await withTaskCancellationHandler {
                    var array: [Element] = []
                    
                    while let next = try await stream.next() {
                        array.append(next)
                    }
                    
                    return array
                } onCancel: {
                    _cancel()
                }
            } catch {
                _cancel()
                throw error as! Failure
            }
        }
    }
    
    /// Calls the given closure on each element in the stream using a `taskGroup`.
    ///
    /// ### Closure parameters
    /// `index`
    ///
    /// The index of the element.
    ///
    /// `element`
    ///
    /// The contained value of the element.
    ///
    /// ### Discussion
    /// The `body` is called concurrently. To call in serial, `while`-loop on ``next()`` instead.
    ///
    /// > Tip:
    /// > Due to the design of ``ConcurrentStream``, instead of looping and adding tasks to a `taskGroup`, you could use the this function.
    /// > ```swift
    /// > await (0...index).stream.forEach(...)
    /// > ```
    /// > This function is equivalent to the following in both performance and result
    /// > ```
    /// > await withTaskGroup(of: Int.self) { taskGroup in
    /// >     for (i, e) in (0...index).enumerated() {
    /// >         taskGroup.addTask(...)
    /// >     }
    /// > }
    /// > ```
    ///
    /// - Complexity: A `taskGroup` is created to enumerate the values.
    ///
    /// > Returns:
    /// > The function is returned after the `taskGroup` completes.
    ///
    /// - Parameters:
    ///   - body: A closure that takes an element of the sequence as a parameter.
    ///
    /// - throws: This function could throw ``Failure``, `E`, or `CancelationError`.
    @inlinable
    public func forEach<E>(_ body: @escaping @Sendable (_ index: Int, _ element: Element) async throws(E) -> Void) async throws(any Error) where E: Error {
        do {
            if #available(macOS 14, iOS 17, watchOS 10, tvOS 17, *) {
                try await withThrowingDiscardingTaskGroup { group in
                    var index = 0
                    while let next = try await self.next() {
                        let _index = index
                        nonisolated(unsafe)
                        let _next = consume next  // Nonisolated as I do not want to restrain `Element` to `Sendable` for now.
                        
                        await Task.yield()
                        guard group.addTaskUnlessCancelled(priority: nil, operation: {
                            await Task.yield()
                            try Task.checkCancellation()
                            
                            try await body(_index, _next)
                        }) else { throw CancellationError() } // manually throw to catch.
                        index &+= 1
                    }
                }
            } else {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    var index = 0
                    while let next = try await self.next() {
                        let _index = index
                        nonisolated(unsafe)
                        let _next = consume next  // FIXME: isolated?
                        
                        await Task.yield()
                        guard group.addTaskUnlessCancelled(priority: nil, operation: {
                            await Task.yield()
                            try Task.checkCancellation()
                            
                            try await body(_index, _next)
                        }) else { throw CancellationError() }
                        index &+= 1
                    }
                }
            }
        } catch {
            self.cancel()
            throw error
        }
    }
    
}
