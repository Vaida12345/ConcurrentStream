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
        consuming get async throws {
            let stream = consume self
            return try await withTaskCancellationHandler {
                var array: [Element] = []
                
                while let next = try await stream.next() {
                    array.append(next)
                }
                
                return array
            } onCancel: {
                stream.cancel()
            }

        }
    }
    
    /// Calls the given closure on each element in the stream using a `taskGroup`.
    ///
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
    /// - Returns: The function is returned after the `taskGroup` completes.
    ///
    /// - Parameters:
    ///   - body: A closure that takes an element of the sequence as a parameter.
    ///   - index: The index of the element.
    ///   - element: The contained value of the element.
    @inlinable
    public func forEach(_ body: @escaping (_ index: Int, _ element: Element) async throws -> Void) async throws {
        if #available(macOS 14, iOS 17, watchOS 10, tvOS 17, *) {
            try await withThrowingDiscardingTaskGroup { group in
                var index = 0
                while let next = try await self.next() {
                    let _index = index
                    group.addTask {
                        try Task.checkCancellation()
                        try await body(_index, next)
                    }
                    index &+= 1
                }
            }
        } else {
            try await withThrowingTaskGroup(of: Void.self) { group in
                var index = 0
                while let next = try await self.next() {
                    let _index = index
                    group.addTask {
                        try Task.checkCancellation()
                        try await body(_index, next)
                    }
                    index &+= 1
                }
            }
        }
    }
    
}
