# ``Stratum/ConcurrentStream``

A stream, where each block works concurrently if possible.


## Overview

A stream implementation indicates that the initialization returns before all of its elements completes. This is a lazy operation, and the elements are only calculated in call of ``ConcurrentStream/makeAsyncIterator(sorted:)``.

`ConcurrentStream` is better than `TaskGroup` that one do not need to `wait` for all the elements within the closure. In this implementation, the iterator is escaped as a stream.

- Warning: A stream is fragile, elements are discarded during traversal.


## Relationship with Sequence

As `Sequence` and `AsyncSequence`, the ``ConcurrentStream`` is constructed using an ``ConcurrentStreamIterator``, which requires the implementation of ``ConcurrentStreamIterator/next()``. The requirement of `next` is defined as:

```swift
mutating func next() async throws -> Element?
```

Hence, this iterator can be used as a encapsulation of `AsyncIteratorProtocol` and `IteratorProtocol`. In this implementation, however, a container was used to bridge between ``ConcurrentStreamIterator`` and these protocols.

As `IteratorProtocol`, `Element` is required during definition. In this way, the type-casting can be omitted.

```swift
func makeIterator() async -> any ConcurrentStreamIterator<Int> {
    ...
}

var iterator = await makeIterator()

while let next = try await iterator.next() {
    ...
}
```

This this case, `next` is `Int`, and `iterator` is `any ConcurrentStreamIterator<Int>`. Unlike `AsyncIteratorProtocol`, you do not need to type-caset. 


## Usage

A stream can be created using `.stream` on a `Sequence` or an `AsyncSequence`.

```swift
try await (1...1000)
    .stream
    .map { $0 % 2 }
    .unique()
    .enumerate { index, value in
        
    }
```

note that the call is not in order, which is expected. One should only relay on the index, not the order.


### Obtaining the sequence

An ``ConcurrentStreamIterator`` (stream, single-threaded) can be retrieved given ``makeAsyncIterator(sorted:)``. The unsorted iterator requires do not buffer and hence performs slightly better. 

The iterator is optimized, and overhead is kept minimum when it is a ``ConcurrentStreamSequence``. 

```swift
try await (1...1000)
    .stream
    .forEach { index in
        
    }
```

This performs the same as

```swift
for i in 1...1000 {
    
}
```

### Converting the result

The result stream can be converted to `Array` using ``sequence`` or `AsyncThrowingStream` using ``async``.

One can also choose to ``enumerate(_:)`` on the stream, which provides the index with the element; or ``forEach(_:)``, where the order of traversal is not guaranteed. 


## Throwing

The closure should only throw when one needs to cancel the pending operations and throw the error, which will be captured in

```swift
while let next = try await iterator.next
```

Otherwise, returns a `nil` would be a better choice, allowing the stream to keep reporting the valid outputs.


### rethrows implementation

The ``ConcurrentStream`` protocol is marked as `@rethrows`, hence some methods only throws when the protocol requirement, ie, ``build(source:)``, throws. However, this requires the compiler knowing the exact ``ConcurrentStream`` and ``ConcurrentStreamIterator`` that it is working with. `any ConcurrentStream<Element>` or even a generic type alias would not satisfy this requirement. Hence, due to this language limitation, and `TaskGroup` / `ThrowingTaskGroup`, the implementation would throw nevertheless. 

You may encounter cases where `try` is required when it would never throw.

```swift
try await (1...1000)
    .stream
    .map { $0 % 2 }
    .sequence
```

## Implementation notes 

When using a `Task { }` to obtain ``ConcurrentStreamIterator/next()``, remember to mark the priority of the `Task` above `.medium`, otherwise the system would try to complete the iterator before entering the task.


## Topics

### Mapping

- ``map(to:_:)``
- ``compactMap(to:_:)``
- ``flatMap(toStreamOf:_:)-3dz37``
- ``compacted()``
- ``unique()``


### min and max

- ``min()``
- ``min(by:)``
- ``max()``
- ``max(by:)``


### Finding Element

- ``contains(_:)``
- ``contains(where:)``
- ``allSatisfy(_:)``
- ``allEqual()``
- ``allEqual(_:)``


### Filtering

- ``filter(_:)``
- ``drop(while:)``


### Obtaining Results

- ``count(where:)``
- ``reduce(_:_:)``
- ``reduce(into:_:)``


### Enumeration

- ``async``
- ``sequence``
- ``forEach(_:)``
- ``enumerate(_:)``


### Iterator

- ``makeAsyncIterator(sorted:)``
- ``ConcurrentStreamIterator``


### Iterator to Sequence

- ``ConcurrentStreamSequence``


### Protocol Requirements
The stream is modeled as as a series of operations to ``source``, which is of type ``SourceIterator``. Each operation is defined in ``build(source:)``. ``Element`` represents the output. `next()` was avoided intentionally to achieve a lazy concurrent stream. ``Iterator`` represents the finalized iterator, required for generics.

- ``source``
- ``build(source:)``
- ``Element``
- ``SourceIterator``
- ``Iterator``


### Methods of same signature

- <doc:AnyConcurrentStream>

### Auxiliary

- <doc:ConcurrentStreamAuxiliary>
