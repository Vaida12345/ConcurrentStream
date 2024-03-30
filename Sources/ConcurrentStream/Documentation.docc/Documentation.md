# ``ConcurrentStream``

The framework of ``ConcurrentStream/ConcurrentStream``.

## Overview

The ``ConcurrentStream`` aims to combine the functionality of execution in parallel and `AsyncSequence`.

- Creation of a stream dispatches the work and returns immediately.
- ``ConcurrentStream/ConcurrentStream/next()`` would wait for the work to complete.

- Warning: A stream is fragile, elements are discarded during traversal. Hence do never reuse a stream.


## Getting Started

`ConcurrentStream` uses [Swift Package Manager](https://www.swift.org/documentation/package-manager/) as its build tool. If you want to import in your own project, it's as simple as adding a `dependencies` clause to your `Package.swift`:
```swift
dependencies: [
    .package(name: "ConcurrentStream", 
             path: "~/Library/Mobile Documents/com~apple~CloudDocs/DataBase/Projects/Packages/ConcurrentStream")
]
```
and then adding the appropriate module to your target dependencies.

### Using Xcode Package support

You can add this framework as a dependency to your Xcode project by clicking File -> Swift Packages -> Add Package Dependency. The package is located at:
```
~/Library/Mobile Documents/com~apple~CloudDocs/DataBase/Projects/Packages/ConcurrentStream
```


## Topics

### The design

You can read more about the design of `ConcurrentStream` and comparison with `taskGroup` here

- <doc:Principle>


### Concurrent Stream

- ``ConcurrentStream/ConcurrentStream``
