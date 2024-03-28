//
//  ConcurrentStream Extensions.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


extension ConcurrentStream {
    
    /// Creates an array and waits for the elements to fill.
    ///
    /// This is a heavy operation, where operations defined are finally applied. The returned `sequence` is in the same order as the input.
    ///
    /// - Complexity: O(*n*).
    @inlinable
    public var sequence: Array<Element> {
        get async throws {
            var array: [Element] = []
            var iterator = await self.makeAsyncIterator(sorted: true)
            
            while let next = try await iterator.next() {
                array.append(next)
            }
            
            return array
        }
    }
    
    /// Returns a Boolean value that indicates whether the stream contains the given element.
    ///
    /// - Parameters:
    ///   - search: The element to find in the stream.
    ///
    /// - Complexity: O(*n*), with early return.
    @inlinable
    public func contains(_ search: Self.Element) async rethrows -> Bool where Element: Comparable {
        var iterator = await self.makeAsyncIterator(sorted: false)
        
        while let next = try await iterator.next() {
            if (next == search) {
                iterator.cancel()
                return true
            }
        }
        
        return false
    }
    
    /// Returns a Boolean value that indicates whether the stream contains an element that satisfies the given predicate.
    ///
    /// - Parameters:
    ///   - predicate: A closure that takes an element of the stream as its argument and returns a Boolean value that indicates whether the passed element represents a match.
    ///
    /// - Complexity: O(*n*), with early return.
    @inlinable
    public func contains(where predicate: (Self.Element) async throws -> Bool) async rethrows -> Bool {
        var iterator = await self.makeAsyncIterator(sorted: false)
        
        while let next = try await iterator.next() {
            if try await (predicate(next)) {
                iterator.cancel()
                return true
            }
        }
        
        return false
    }
    
    /// Returns a Boolean value that indicates whether all elements produced by the stream satisfy the given predicate.
    ///
    /// - Parameters:
    ///   - predicate: A closure that takes an element of the stream as its argument and returns a Boolean value that indicates whether the passed element satisfies a condition.
    ///
    /// - Complexity: O(*n*), with early return.
    @inlinable
    public func allSatisfy(_ predicate: (Self.Element) async throws -> Bool) async rethrows -> Bool {
        var iterator = await self.makeAsyncIterator(sorted: false)
        
        while let next = try await iterator.next() {
            if try await (!predicate(next)) {
                iterator.cancel()
                return false
            }
        }
        
        return true
    }
    
    /// Returns a boolean value determining whether all the elements in the stream are equal given the `predicate`.
    ///
    /// - Parameters:
    ///   - predicate: A closure which returns a boolean value determining whether its two arguments are equal.
    ///
    /// - Returns: The return value is `true` if the array is empty.
    ///
    /// - Complexity: O(*n*), with early exit.
    @inlinable
    public func allEqual(_ predicate: (_ lhs: Element, _ rhs: Element) async throws -> Bool) async rethrows -> Bool {
        
        var iterator = await self.makeAsyncIterator(sorted: false)
        guard let firstElement = try await iterator.next() else { return true }
        
        while let nextElement = try await iterator.next() {
            guard try await predicate(firstElement, nextElement) else {
                iterator.cancel()
                return false
            }
        }
        
        return true
    }
    
    /// Returns a boolean value determining whether all the elements in the stream are equal.
    ///
    /// - Returns: The return value is `true` if the array is empty.
    ///
    /// - Complexity: O(*n*), with early exit.
    @inlinable
    public func allEqual() async rethrows -> Bool where Element: Equatable {
        try await self.allEqual(==)
    }
    
    /// Returns the number of elements where the `predicate` is met.
    ///
    /// - Parameters:
    ///   - predicate: A closure that takes an element as its argument and returns a Boolean value that indicates whether the passed element represents a match.
    ///
    /// - Complexity: O(*n*).
    @inlinable
    public func count(where predicate: (Element) async throws -> Bool) async rethrows -> Int {
        try await self.reduce(0) { await $0 &+ (try predicate($1) ? 1 : 0) }
    }
    
    /// Returns a compact mapped stream.
    ///
    /// In this implementation, `.map(:_).compacted()` performs the same as `.compactMap(:_)`. The overhead of making an iterator is kept minimum.
    ///
    /// - Complexity: O(*n*), lazily.
    @inlinable
    public func compacted<Unwrapped>() async -> some ConcurrentStream<Unwrapped> where Element == Unwrapped? {
        await self.compactMap { $0 }
    }
    
    /// Returns the minimum element in an stream of comparable elements.
    ///
    /// - Important: Upon a tie, the returned element is not guaranteed in any order.
    ///
    /// - Returns: `nil` if and only if the stream is empty.
    ///
    /// - Complexity: O(*n*).
    @warn_unqualified_access
    @inlinable
    public func min() async rethrows -> Element? where Element: Comparable {
        var iterator = await self.makeAsyncIterator(sorted: false)
        var min: Element? = nil
        
        while let next = try await iterator.next() {
            if min != nil {
                min = min! < next ? min : next
            } else {
                min = next
            }
        }
        
        return min
    }
    
    /// Returns the minimum element in the stream, using the given predicate as the comparison between elements.
    ///
    /// - Important: Upon a tie, the returned element is not guaranteed in any order.
    ///
    /// - Parameters:
    ///   - areInIncreasingOrder: A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    ///
    /// - Returns: `nil` if and only if the stream is empty.
    ///
    /// - Complexity: O(*n*).
    @warn_unqualified_access
    @inlinable
    public func min(by areInIncreasingOrder: (Self.Element, Self.Element) async throws -> Bool) async rethrows -> Self.Element? {
        var iterator = await self.makeAsyncIterator(sorted: false)
        var min: Element? = nil
        
        while let next = try await iterator.next() {
            if min != nil {
                min = try await areInIncreasingOrder(min!, next) ? next : min
            } else {
                min = next
            }
        }
        
        return min
    }
    
    /// Returns the maximum element in an stream of comparable elements.
    ///
    /// - Important: Upon a tie, the returned element is not guaranteed in any order.
    ///
    /// - Returns: `nil` if and only if the stream is empty.
    ///
    /// - Complexity: O(*n*).
    @warn_unqualified_access
    @inlinable
    public func max() async rethrows -> Element? where Element: Comparable {
        var iterator = await self.makeAsyncIterator(sorted: false)
        var max: Element? = nil
        
        while let next = try await iterator.next() {
            if max != nil {
                max = max! > next ? max : next
            } else {
                max = next
            }
        }
        
        return max
    }
    
    /// Returns the maximum element in the stream, using the given predicate as the comparison between elements.
    ///
    /// - Important: Upon a tie, the returned element is not guaranteed in any order.
    ///
    /// - Parameters:
    ///   - areInIncreasingOrder: A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    ///
    /// - Returns: `nil` if and only if the stream is empty.
    ///
    /// - Complexity: O(*n*).
    @warn_unqualified_access
    @inlinable
    public func max(by areInIncreasingOrder: (Self.Element, Self.Element) async throws -> Bool) async rethrows -> Self.Element? {
        var iterator = await self.makeAsyncIterator(sorted: false)
        var max: Element? = nil
        
        while let next = try await iterator.next() {
            if max != nil {
                max = try await areInIncreasingOrder(max!, next) ? max : next
            } else {
                max = next
            }
        }
        
        return max
    }
    
    /// Returns the result of combining the elements of the stream using the given closure.
    ///
    /// - Important: The order of in which `nextPartialResult` calls elements is not guaranteed.
    ///
    /// - Important: `nextPartialResult` is called in serial.
    ///
    /// - Parameters:
    ///   - initialResult: The value to use as the initial accumulating value. The nextPartialResult closure receives initialResult the first time the closure runs.
    ///   - nextPartialResult: A closure that combines an accumulating value and an element of the stream into a new accumulating value, for use in the next call of the nextPartialResult closure or returned to the caller.
    ///
    /// - Complexity: O(*n*).
    @inlinable
    public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Self.Element) async throws -> Result) async rethrows -> Result {
        var iterator = await self.makeAsyncIterator(sorted: false)
        var result = initialResult
        
        while let next = try await iterator.next() {
            result = try await nextPartialResult(result, next)
        }
        
        return result
    }
    
    /// Returns the result of combining the elements of the stream using the given closure, given a mutable initial value.
    ///
    /// - Important: The order of in which `nextPartialResult` calls elements is not guaranteed.
    ///
    /// - Important: `nextPartialResult` is called in serial.
    ///
    /// - Parameters:
    ///   - initialResult: The value to use as the initial accumulating value. The nextPartialResult closure receives initialResult the first time the closure executes.
    ///   - nextPartialResult: A closure that combines an accumulating value and an element of the stream into a new accumulating value, for use in the next call of the nextPartialResult closure or returned to the caller.
    ///
    /// - Complexity: O(*n*).
    @inlinable
    public func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Self.Element) async throws -> Void) async rethrows -> Result {
        var iterator = await self.makeAsyncIterator(sorted: false)
        var result = initialResult
        
        while let next = try await iterator.next() {
            try await updateAccumulatingResult(&result, next)
        }
        
        return result
    }
    
    /// Calls the given closure on each element with its index in the sequence. Concurrent Operation.
    ///
    /// ## Sample Usage
    ///
    /// The iterator is optimized, and overhead is kept minimum when it is a ``ConcurrentStreamSequence``.
    ///
    /// ```swift
    /// try await (1...1000)
    ///     .stream
    ///     .enumerate { index, value in
    ///
    ///     }
    /// ```
    ///
    /// This performs at least the same as
    ///
    /// ```swift
    /// for i in 1...1000 {
    ///
    /// }
    /// ```
    ///
    /// The `body` is called concurrently. To call in serial, use ``async``, then call `enumerate` instead.
    ///
    /// Cancellation on which the task is running will cancel this function.
    ///
    /// - Important: The order in which `body` is called is not guaranteed, relay on `index` instead.
    ///
    /// - Parameters:
    ///   - body: A closure that takes an element of the sequence and its index as parameters.
    ///     - index: The 0-based index of the given element.
    ///     - value: The contained value of the element.
    ///
    /// - Complexity: O(*n*).
    @inlinable
    public func enumerate(_ body: @escaping @Sendable (_ index: Int, _ value: Element) async throws -> Void) async throws {
        
        try await withThrowingTaskGroup(of: (index: Int, value: Element?).self) { group in
            var _block = self.source
            var count = 0
            while let value = try await _block.next() {
                let _count = count
                
                group.addTask(priority: .medium) {
                    try Task.checkCancellation()
                    return try await (_count, self.build(source: value))
                }
                
                count &+= 1
            }
            
            
            func getNext(index: inout Int, elementIndex: inout Int, buffer: inout Dictionary<Int, Element?>) async throws -> Element? {
                while buffer[index] == nil {
                    try Task.checkCancellation()
                    guard let word = try await group.next() else {
                        return nil
                    } // the only place where `nil` is returned.
                    
                    buffer.updateValue(word.1, forKey: word.0)
                }
                
                let value = buffer.removeValue(forKey: index)!
                index += 1
                
                if let value {
                    defer { elementIndex += 1 }
                    return value // return the element
                } else {
                    // no element here, caused by the block building it, not by waiting.
                    return try await getNext(index: &index, elementIndex: &elementIndex, buffer: &buffer) // get next element
                }
            }
            
            if #available(macOS 14, iOS 17, watchOS 10, tvOS 17, *) {
                try await withThrowingDiscardingTaskGroup { innerGroup in
                    var iteratorIndex = 0
                    var elementIndex = 0
                    var buffer: Dictionary<Int, Element?> = [:]
                    
                    while let element = try await getNext(index: &iteratorIndex, elementIndex: &elementIndex, buffer: &buffer) {
                        let index = iteratorIndex
                        innerGroup.addTask {
                            try Task.checkCancellation()
                            try await body(index, element)
                        }
                    }
                }
            } else {
                try await withThrowingTaskGroup(of: Void.self) { innerGroup in
                    var iteratorIndex = 0
                    var elementIndex = 0
                    var buffer: Dictionary<Int, Element?> = [:]
                    
                    while let element = try await getNext(index: &iteratorIndex, elementIndex: &elementIndex, buffer: &buffer) {
                        let index = iteratorIndex
                        innerGroup.addTask(priority: .high) {
                            try Task.checkCancellation()
                            try await body(index, element)
                        }
                    }
                    
                    try await innerGroup.waitForAll()
                }
            }
        }
    }
    
    /// Calls the given closure on each element in the stream. Concurrent Operation.
    ///
    /// The iterator is optimized, and overhead is kept minimum when it is a ``ConcurrentStreamSequence``.
    ///
    /// ```swift
    /// try await (1...1000)
    ///     .stream
    ///     .forEach { index in
    ///
    ///     }
    /// ```
    ///
    /// This performs the same as
    ///
    /// ```swift
    /// for i in 1...1000 {
    ///     
    /// }
    /// ```
    ///
    /// The `body` is called concurrently. To call in serial, use ``async``, then call `forEach` instead.
    ///
    /// Cancellation on which the task is running will cancel this function.
    ///
    /// - Warning: This method is **always** preferred than making an iterator and then call a task group.
    ///
    /// - Important: The order in which the `body` is called is not guaranteed.
    ///
    /// - Complexity: O(*n*).
    ///
    /// - Parameters:
    ///   - body: A closure that takes an element of the sequence as a parameter.
    ///     - value: The contained value of the element.
    @inlinable
    public func forEach(_ body: @escaping @Sendable (_ element: Element) async throws -> Void) async throws {
        if #available(macOS 14, iOS 17, watchOS 10, tvOS 17, *) {
            try await withThrowingDiscardingTaskGroup { group in
                var _block = self.source
                while let next = try await _block.next() {
                    group.addTask {
                        try Task.checkCancellation()
                        guard let next = try await self.build(source: next) else { return }
                        try await body(next)
                    }
                }
            }
        } else {
            try await withThrowingTaskGroup(of: Void.self) { group in
                var _block = self.source
                while let next = try await _block.next() {
                    group.addTask {
                        try Task.checkCancellation()
                        guard let next = try await self.build(source: next) else { return }
                        try await body(next)
                    }
                    
                }
                
                try await group.waitForAll()
            }
        }
    }
}


extension ConcurrentStream {
    
    
    /// Creates a concurrent stream that maps the given closure over the stream’s elements.
    ///
    /// - Parameters:
    ///   - type: The return type. One can provide this explicitly to ease the pain on the compiler (and hence the programmer).
    ///   - transform: A mapping closure. transform accepts an element of this sequence as its parameter and returns a transformed value of the same or of a different type.
    ///
    /// - Complexity: O(*n*), lazily.
    @inlinable
    public func map<T>(to type: T.Type = T.self, _ transform: @escaping @Sendable (Element) async throws -> T) async -> some ConcurrentStream<T> where T: Sendable {
        ConcurrentMapStream(source: self.source) {
            guard let element = try await self.build(source: $0) else { return nil }
            return try await transform(element)
        }
    }
    
    /// Creates a concurrent stream that maps the given closure over the stream’s elements, omitting results that don’t return a value.
    ///
    /// - Parameters:
    ///   - type: The unwrapped return type. One can provide this explicitly to ease the pain on the compiler (and hence the programmer).
    ///   - transform: A mapping closure. transform accepts an element of this sequence as its parameter and returns a transformed value of the same or of a different type.
    ///
    /// - Complexity: O(*n*), lazily.
    @inlinable
    public func compactMap<T>(to type: T.Type = T.self, _ transform: @escaping @Sendable (Element) async throws -> T?) async -> some ConcurrentStream<T> where T: Sendable {
        ConcurrentMapStream(source: self.source) {
            guard let element = try await self.build(source: $0) else { return nil }
            return try await transform(element)
        }
    }
    
    /// Creates a concurrent stream containing the concatenated results of calling the given transformation with each element of this stream.
    ///
    /// In the `transform` closure, a stream is required.
    ///
    /// ```swift
    /// (0..<10).stream
    ///     .flatMap {
    ///         [Int](0..<10).stream
    ///     }
    /// ```
    ///
    /// In the complicated cases where an `any ConcurrentStream<Element>` is returned (instead of `some ConcurrentStream<Element>`), method of this same signature is called instead. This is automatically handled by the compiler.
    ///
    /// - Note: `nil` values in the inner stream are also omitted, unless indicated otherwise by `type`.
    ///
    /// - Parameters:
    ///   - type: The element type of the returned stream. One can provide this explicitly to ease the pain on the compiler (and hence the programmer).
    ///   - transform: A mapping closure. transform accepts an element of this sequence as its parameter and returns a transformed value of the same or of a different type.
    ///
    /// - Complexity: O(*n*), lazily.
    @inlinable
    public func flatMap<SegmentOfResult>(toStreamOf type: SegmentOfResult.Element.Type = SegmentOfResult.Element.self, _ transform: @escaping @Sendable (Element) async throws -> SegmentOfResult?) async -> some ConcurrentStream<SegmentOfResult.Element> where SegmentOfResult: ConcurrentStream {
        await ConcurrentStreamSequence(iterator: ConcurrentFlatMapStreamIterator<SourceIterator, SegmentOfResult>(iterator: self.source) {
            guard let element = try await self.build(source: $0) else { return nil }
            return try await transform(element)
        })
    }
    
    /// Creates a concurrent stream containing the concatenated results of calling the given transformation with each element of this stream.
    ///
    /// In the `transform` closure, a stream is required.
    ///
    /// ```swift
    /// (0..<10).stream
    ///     .flatMap {
    ///         [Int](0..<10).stream
    ///     }
    /// ```
    ///
    /// In the simple cases where an `some ConcurrentStream<Element>` is returned (instead of `any ConcurrentStream<Element>`), method of this same signature is called instead. This is automatically handled by the compiler.
    ///
    /// - Note: `nil` values in the inner stream are also omitted, unless indicated otherwise by `type`.
    ///
    /// - Parameters:
    ///   - type: The element type of the returned stream. One can provide this explicitly to ease the pain on the compiler (and hence the programmer).
    ///   - transform: A mapping closure. transform accepts an element of this sequence as its parameter and returns a transformed value of the same or of a different type.
    ///
    /// - Complexity: O(*n*), lazily.
    @inlinable
    public func flatMap<T>(toStreamOf type: T.Type = T.self, _ transform: @escaping @Sendable (Element) async throws -> (any ConcurrentStream<T>)?) async -> some ConcurrentStream<T> {
        await ConcurrentStreamSequence(iterator: ConcurrentAnyFlatMapStreamIterator<SourceIterator, T>(source: self.source) {
            guard let element = try await self.build(source: $0) else { return nil }
            return try await transform(element)
        })
    }
    
    /// Creates a concurrent stream that contains, in order, the elements of the base sequence that satisfy the given predicate.
    ///
    /// The filtering does the opposite of ``drop(while:)``.
    ///
    /// - Parameters:
    ///   - isIncluded: A closure that takes an element of the stream as its argument and returns a Boolean value that indicates whether to include the element in the filtered sequence.
    ///
    /// - Complexity: O(*n*), lazily.
    @inlinable
    public func filter(_ isIncluded: @escaping (Self.Element) async throws -> Bool) async -> some ConcurrentStream<Element> {
        ConcurrentMapStream(source: self.source) {
            guard let element = try await self.build(source: $0) else { return nil }
            return try await isIncluded(element) ? element : nil
        }
    }
    
    /// Omits elements from the base stream until a given closure returns false, after which it passes through all remaining elements.
    ///
    /// Drop while does the opposite of ``filter(_:)``.
    ///
    /// - Parameters:
    ///   - predicate: A closure that takes an element as a parameter and returns a Boolean value indicating whether to drop the element from the modified sequence.
    ///
    /// - Complexity: O(*n*), lazily.
    @inlinable
    public func drop(while predicate: @escaping (Self.Element) async throws -> Bool) async -> some ConcurrentStream<Element> {
        ConcurrentMapStream(source: self.source) {
            guard let element = try await self.build(source: $0) else { return nil }
            return try await predicate(element) ? nil : element
        }
    }
    
    /// Removes the repeated elements of the stream, leaving only the entries different from each other.
    ///
    /// > Example:
    /// >
    /// > ```swift
    /// > [1, 2, 3, 1].unique() // [1, 2, 3]
    /// > ```
    ///
    /// - Returns: The array without repeated elements.
    ///
    /// - Complexity: O(*n*), where *n* is the length of this sequence.
    public func unique() -> some ConcurrentStream where Element: Hashable {
        ConcurrentUniqueStream(source: self.source, previousWork: self.build)
    }
    
}
