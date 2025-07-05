# ConcurrentStream

The ``ConcurrentStream`` aims to combine the functionality of execution in parallel and `AsyncSequence`.

```swift
let stream = (1...100).stream.map(heavyWork)

while let next = await stream.next() {
    ...
}
```
The `heavyWork`s are executed in parallel, while the completed ones are reported in order.


## Getting Started

`ConcurrentStream` uses [Swift Package Manager](https://www.swift.org/documentation/package-manager/) as its build tool. If you want to import in your own project, it's as simple as adding a `dependencies` clause to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://www.github.com/Vaida12345/ConcurrentStream", from: "1.0.1")
]
```
and then adding the appropriate module to your target dependencies.

### Using Xcode Package support

You can add this framework as a dependency to your Xcode project by clicking File -> Swift Packages -> Add Package Dependency. The package is located at:
```
https://www.github.com/Vaida12345/ConcurrentStream
```

## Documentation
Full documentation available as DocC ([View raw ConcurrentStream documentation](/Sources/ConcurrentStream/Documentation.docc/ConcurrentStream.md)).

## Implementation Details

### A stream, not a sequence

As the name suggests, the package provides a stream, not a sequence. Which means that you cannot iterate using `for`-loop. However, you could
- use `stream.next()`
- use `stream.sequence` to convert it into a sequence. The `seqeunce` method would wait for all elements to present before returning.
- use `stream.async` to convert it into an async sequence. This method returns immediately, and new elements can be obtained using `for await`.

> Important:
> A stream is fragile, elements are discarded during traversal. Hence do never reuse a stream. (Similar to `TaskGroup`)

### Eazy conversion

This framework also offers eazy ways to convert between stream and sequence. For example,
```swift
for i in await (1...10).stream.sequence {
    print(i)
}
```

Would provide exactly the same as 
```swift
for i in (1...10) {
    print(i)
}
```

With arguably similar performance.

**To read more about choice and implementation details, see [Principle](/Sources/ConcurrentStream/Documentation.docc/Principle.md)**

### Typed Throws

With `Swift6.0`, this package also has typed throws implemented. You no longer need to call `try` when it is impossible to throw.
