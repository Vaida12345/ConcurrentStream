# Principle

This summary of what `ConcurrentStream` aims to achieve.


## TaskGroup

The `TaskGroup` offers a structure that can execute its tasks concurrently, while providing a stream.

### Concurrency

This article will superficially refer to concurrency as the ability to execute tasks in parallel. Please note the difference between these two concepts, which can be found in detail in the `Stratum` package.


### Equivalent of `map`

```swift
await withTaskGroup(of: Int.self) { taskGroup in
    for i in 0...100 {
        taskGroup.addTask {
            i * 2
        }
    }

    for await result in taskGroup {
        print(result)
    }
}
```

Note that due to the natural of concurrency, the resulting stream is out of order. A potential workaround could be adding an index to the task group, such as 
```swift
taskGroup.addTask {
    (i, i * 2)
}
```

### Equivalent of `flatMap`

```swift
await withTaskGroup(of: [Int].self) { taskGroup in
    for i in 0...10 {
        taskGroup.addTask {
            [Int](0...i)
        }
    }

    await withTaskGroup(of: Int.self) { _taskGroup in
        for await result in taskGroup {
            for element in result {
                _taskGroup.addTask {
                    element * 2
                }
            }
        }

        for await value in _taskGroup {
            print(value)
        }
    }
}
```

This is already starting to gain complexity. Attempting to give order to the results would only make worse.

```swift
await withTaskGroup(of: (Int, [Int]).self) { taskGroup in
    for i in 0...10 {
        taskGroup.addTask {
            (i, [Int](0...i))
        }
    }

    await withTaskGroup(of: ((Int, Int), Int).self) { _taskGroup in
        for await result in taskGroup {
            for (offset, element) in result.1.enumerated() {
                _taskGroup.addTask {
                    ((result.0, offset), element * 2)
                }
            }
        }

        for await value in _taskGroup {
            print(value)
        }
    }
}
```

The results, such as `((10, 8), 16)` was identified using index of `(10, 8)`.

---

The use of `flatMap` in `TaskGroup` could be troublesome, as it would involve returning the `TaskGroup` of the child task. 

### Equivalent of `compactMap`

```swift
await withTaskGroup(of: Int?.self) { taskGroup in
    for i in 0...100 {
        taskGroup.addTask {
            guard i % 2 != 0 else { return nil }
            return i * 2
        }
    }

    for await result in taskGroup.compactMap({ $0 }) {
        print(result)
    }
}
```



### Drawbacks

The drawback is that `TaskGroup` is only available in the closure, similar to the behavior of an `UnsafeMutablePointer`. Such behavior made the abstraction on `TaskGroup` difficult.

In this way, a `TaskGroup` could never be passed outside its function. Hence, it is impossible to treat it as `Array` or `some AsyncSequence`.

The `ConcurrentStream` aims to achieve the same, while making it available outside the closure.


## ConcurrentStream

The `ConcurrentStream` aims to combine `DispatchQueue.perform` and `AsyncSequence`.

- Creation of a stream dispatches the work and returns immediately.
- ``ConcurrentStream/next()`` would wait for the work to complete.
- A stream can **never** be reused.


> Example:
> Using `ConcurrentMapStream` as an example.

### Initialization

In the initialization phase, a `taskGroup` is created and detached. The results of the `taskGroup` is reported using an `AsyncStream` continuation.

Multiple `yield` and cancelation checking points were created throughout the creation and execution of the child tasks of `taskGroup`. Using the following code,
```swift
var iterator = await ConcurrentStreamOrderedIterator(stream: stream)

while let next = try await iterator.next() {
    print(">>", next)
}
```
You can see a recurring sequence where a task is *created*, *executed*, and *reported* for each child. This means that typically, the report for the previous child comes before the creation of the next child task. You will also observe that the sequence occurs in batches, matching the number of cores with which a computer is equipped.

### The Order

The sequence in which results are yielded upon invoking `next` corresponds to the sequence in the originating `stream`. The implementation entails the use of a dictionary buffer, which retains any pending values until the targeted value is generated.

### Cancellation

As a `taskGroup` waits for all of its child tasks to complete before returning, the `taskGroup` used in the iterator is detached. Hence manual task cancelation is required.

- Note: Due to the nature of concurrency, if the closure does not implement checking cancelation, the submitted tasks to ``ConcurrentStream/map(_:)``-like streams cannot be cancelled until these closure finish.

The tasks can be cancelled in three ways.
- Releasing reference to the `stream`. (Cancelation in `deinit`)
- Automatically cancelled when the parent `Task` executing  ``ConcurrentStream/next()`` is cancelled.
- Calling ``ConcurrentStream/cancel`` explicitly.

The task is also cancelled automatically when:
- An error is thrown in the closure (``ConcurrentStream/map(_:)``-like).
- Child streams are cancelled. (Note: This only goes up, not down)
- Task is cancelled during a bridge method, such as ``ConcurrentStream/sequence``. With the exception of ``ConcurrentStream/async``, which must be cancelled manually.

After the task is cancelled, successive calls to ``ConcurrentStream/next()`` depends on its origin. The stream itself does not store the state of whether it has been cancelled.
- If it does not evolve ``ConcurrentStream/map(_:)``-like: The method is unaffected, why would it be?
- Otherwise this method would return anything left in the buffer, and `nil` in subsequence calls.


This should cover the common use case. In the following example, the stream is canceled immediately due to the release of its reference, caused by the exit of the function.
```swift
Task {
    let stream = (1...10).stream.map { $0 }
}
```

One could also use the `withTaskCancellationHandler` call,

```swift
let stream = some ConcurrentStream

try await withTaskCancellationHandler {
    ...
} onCancel: {
    stream.cancel()
}
```

This is only required when you **do not** interact with the stream in any way. This cannot be done automatically due to the nature of `ConcurrentStream`: The initializer block returns immediately and dispatches the task. The child-generating task is then run on a different task group, independent of the original one. 

As another example, the cancellation of the stream occurs while awaiting the retrieval of the `next` element.
```swift
var iterator = await ConcurrentStreamOrderedIterator(stream: stream)

while let next = try await iterator.next() {
    ...
}
```

### Performance

Using Benchmark, `-O`, the following code
```swift
var stream = await [Int](1...100).stream.map { heavyWork(i: $0) }

while let next = try await stream.next() {

}
```

Performed similar to,
```swift
await withTaskGroup(of: Int.self) { taskGroup in
    for i in 1...100 {
        taskGroup.addTask {
            heavyWork(i: i)
        }
    }
}
```

Similar results can be found for double `map`s.

- Bug: However, there is a ~0.4ms overhead of using concurrent stream iterator.
