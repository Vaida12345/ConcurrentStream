# ``ConcurrentStream``

The framework of ``ConcurrentStream/ConcurrentStream``.

## Overview

The ``ConcurrentStream`` aims to combine the functionality of execution in parallel and `AsyncSequence`.

```swift
let stream = (1...100).stream.map(heavyWork)

while let next = try await stream.next() {
    ...
}
```
The `heavyWork`s are executed in parallel, while the completed ones are reported in order.


## Getting Started

`ConcurrentStream` uses [Swift Package Manager](https://www.swift.org/documentation/package-manager/) as its build tool. If you want to import in your own project, it's as simple as adding a `dependencies` clause to your `Package.swift`:
```swift
dependencies: [
    .package(name: "ConcurrentStream", 
             path: "https://github.com/Vaida12345/ConcurrentStream")
]
```
and then adding the appropriate module to your target dependencies.

### Using Xcode Package support

You can add this framework as a dependency to your Xcode project by clicking File -> Swift Packages -> Add Package Dependency. The package is located at:
```
https://github.com/Vaida12345/ConcurrentStream
```

> Tip: The `ConcurrentStream` is part of the `Stratum` framework. If you have declared `Stratum` as dependency, you can use `ConcurrentStream` by simply `import`ing the framework.


## Topics

### The design

You can read more about the design of `ConcurrentStream` and comparison with `taskGroup` here

- <doc:Principle>


### Concurrent Stream

- ``ConcurrentStream/ConcurrentStream``
