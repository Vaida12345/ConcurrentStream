# ``ConcurrentStream/ConcurrentStream``

A stream, where each block works concurrently if possible.

## Overview

The ``ConcurrentStream`` aims to combine the functionality of execution in parallel and `AsyncSequence`.

- Creation of a stream dispatches the work and returns immediately.
- ``ConcurrentStream/ConcurrentStream/next()`` would wait for the work to complete.

- Warning: A stream is fragile, elements are discarded during traversal. Hence do never reuse a stream.

### Usage

A stream can be created using `.stream` on a `Sequence` or an `AsyncSequence`.

```swift
try await (1...1000)
    .stream
    .map { $0 % 2 }
```

### Cancelation

The stream can be cancelled in three ways.
- Releasing reference to the `stream`. (Cancelation in `deinit`)
- Automatically cancelled when the parent `Task` executing  ``ConcurrentStream/ConcurrentStream/next()`` is cancelled.
- Calling ``ConcurrentStream/ConcurrentStream/cancel()`` explicitly.

This should cover the common use case. You can read details about the `ConcurrentStream` [here](<doc:Principle>).

- Tip: There exists unavoidable overhead due to the use of `AsyncStream` to escape the results of `taskGroup`. Hence aim to reduce the number of `map`-like operations queued.

## Implementation Notes
### Class Protocol

This protocol is a class protocol, due to the fact that
- A class protocol has a `deinit` block, where the task can be cancelled.
- A class protocol has non-mutating next, making the following way of cancelation possible:
```swift
let stream = some ConcurrentStream

try await withTaskCancellationHandler {
    ...
    stream.foo()
} onCancel: {
    iterator.cancel()
}
```

### The order
A stream is always ordered, given the negligible performance difference between an ordered iterator and an unordered one.


## Throwing

The closure should only throw when one needs to cancel the pending operations and throw the error, which will be captured in

```swift
while let next = try await stream.next
```

Otherwise, returns a `nil` would be a better choice, allowing the stream to keep reporting the valid outputs.


### rethrows implementation

A new implementation addressing will come out with Swift6.0.

> Bug:
> You may encounter cases where `try` is required when it would never throw.
> 
> ```swift
> try await (1...1000)
>     .stream
>     .map { $0 % 2 }
>     .sequence
> ```


## Topics

### Creation of stream

The ``ConcurrentStream`` does not offer a direct way of creation. You would always need to bridge from other structures.

- ``Swift/Sequence/stream``

### Obtaining elements explicitly
Returns the next element in the iterator. The elements will always be returned in the order they were submitted.
- ``next()``


### Cancelling stream

This is the explicit way of canceling a stream. A stream would be canceled explicitly when the reference is released and when the parent `Task` is cancelled. [Read more](<doc:Principle>).

- ``cancel()``

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


### Methods of same signature

- <doc:AnyConcurrentStream>

### Auxiliary

- <doc:ConcurrentStreamAuxiliary>
