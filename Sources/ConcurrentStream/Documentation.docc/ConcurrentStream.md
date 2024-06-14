# ``ConcurrentStream/ConcurrentStream``

A stream, where each block works concurrently if possible.

## Overview

The ``ConcurrentStream`` aims to combine the functionality of execution in parallel and `AsyncSequence`.

```swift
let stream = (1...100).stream.map(heavyWork)

while let next = try await stream.next() {
    ...
}
```
The `heavyWork`s are executed in parallel, while the completed ones are reported in order.

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
- Calling ``ConcurrentStream/ConcurrentStream/cancel`` explicitly.

This should cover the common use case. You can read details about the `ConcurrentStream` [here](<doc:Principle>).

### Overhead

There are generally two kinds of operations:

- ``map(_:)-4q8b6``-like, where a `taskGroup` is created and dispatched upon invocation.
- ``compacted()``-like, where a `taskGroup` is not generated. These operations are lightweight and do not involve additional overhead associated with being `async`.

In the first scenario, unavoidable overhead arises from the use of `AsyncStream` to capture the results of the `taskGroup` and the `taskGroup` itself. Therefore, it is advisable to minimize the number of `map`-like operations queued.

- Warning: All methods that take a closure as an argument will create `taskGroup`s to execute the closure.
- Tip: You can determine if a `taskGroup` has been instantiated (thereby causing significant overhead) by examining the function signature. It is necessary to use `await` on methods where a `taskGroup` is created; conversely, `await` is not required when a `taskGroup` has not been instantiated.


## Implementation Notes
### Class Protocol

This protocol is a class protocol, due to the fact that
- A class protocol has a `deinit` block, where the task can be cancelled.
- A class protocol has non-next, making the following way of cancelation possible:
```swift
let stream = some ConcurrentStream
let cancel = stream.cancel

try await withTaskCancellationHandler {
    ...
    stream.foo()
} onCancel: {
    cancel() // the nonisolated cancel 
}
```

### The order
A stream is always ordered, given the negligible performance difference between an ordered iterator and an unordered one.


## Throwing

In ``map(_:)-4q8b6``-like closure, it should only throw when one needs to cancel the pending operations and throw the error, which will be captured in

```swift
while let next = try await stream.next
```

Otherwise, returns a `nil` would be a better choice, allowing the stream to keep reporting the valid outputs.


### rethrows implementation

With typed throws, ``ConcurrentStream`` now only throws when it is required to.

> Example:
> The following will no longer throw in the latest implementations.
> 
> ```swift
> await (1...1000)
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
- ``forEach(_:)``

### Converting stream
- ``sequence``
- ``async``


### Cancelling stream

This is the explicit way of canceling a stream. A stream would be canceled explicitly when the reference is released and when the parent `Task` is cancelled. [Read more](<doc:Principle>).

- ``cancel``


### Lightweight Operations
These operations are lightweight and do not involve additional overhead associated with being `ConcurrentStream`. This is also indicated by the lack of `await` in the function call.

- ``compacted()``
- ``unique()``
- ``flatten()-3mp1s``
- ``+(_:_:)-7m6k2``


### Mappings
These operations involve creation of `taskGroup` in each function call.

- ``map(_:)-4q8b6``
- ``compactMap(_:)-8yxjm``
- ``flatMap(_:)-6o6er``


### Excluding Elements
Note that there is no way to retrieve the excluded elements. These operation themselves are lightweight.

- ``filter(_:)-5v6w8``
