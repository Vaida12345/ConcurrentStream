# Principle

This summary of what ``ConcurrentStream`` aims to achieve.


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

The ``ConcurrentStream`` aims to achieve the same, while making it available outside the closure.


## ConcurrentStream

The ``ConcurrentStream`` aims to combine `DispatchQueue.perform` and `AsyncSequence`.
