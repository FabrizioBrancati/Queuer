<p align="center"><img src="https://github.fabriziobrancati.com/queuer/resources/queuer-banner.png" alt="Queuer Banner"></p>

[![Build Status](https://travis-ci.org/FabrizioBrancati/Queuer.svg?branch=master)](https://travis-ci.org/FabrizioBrancati/Queuer)
[![Codecov](https://codecov.io/gh/FabrizioBrancati/Queuer/branch/master/graph/badge.svg)](https://codecov.io/gh/FabrizioBrancati/Queuer)
[![Documentation](https://github.fabriziobrancati.com/documentation/Queuer/badge.svg)](https://github.fabriziobrancati.com/documentation/Queuer/)
[![codebeat badge](https://codebeat.co/badges/50844e60-f4f2-4f9f-a688-5ccc976b7c8c)](https://codebeat.co/projects/github-com-fabriziobrancati-queuer-master-9833cda0-af64-433d-a08a-cd0d50d6b579)
[![Swift Package Manager Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/Queuer.svg?style=flat)][Documentation]
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/FabrizioBrancati/Queuer/blob/master/LICENSE)
<br>
[![Language](https://img.shields.io/badge/language-Swift%204.0-orange.svg)](https://swift.org/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-ffc713.svg)][Documentation]

---

<p align="center">
    <a href="#features">Features</a> &bull;
    <a href="#requirements">Requirements</a> &bull;
    <a href="#installing">Installing</a> &bull;
    <a href="#usage">Usage</a> &bull;
    <a href="#documentation">Documentation</a> &bull;
    <a href="#changelog">Changelog</a> &bull;
    <a href="#communication">Communication</a> &bull;
    <a href="#contributing">Contributing</a> &bull;
    <a href="#author">Author</a> &bull;
    <a href="#license">License</a>
</p>

---

Features
========

Queuer is a queue manager, built on top of [OperationQueue](https://developer.apple.com/documentation/foundation/operationqueue) and [Dispatch](https://developer.apple.com/documentation/dispatch) (aka GCD).<br>
It allows you to create any synchronous and asynchronous task easily, with just a few lines.

Here is the list of all the features:
- [x] Works on all Swift compatible platforms (even Linux `*`)
- [x] Easy to use
- [x] Well documented (100% documented)
- [x] Well tested (currently 99% code coverage)
- [x] Create an operation block
- [x] Create a single operation
- [x] Create chained operations
- [x] Manage a centralized queue
- [x] Create unlimited queue
- [x] Declare how many concurrent operation a queue can handle
- [x] Create a network request operation `*`
- [ ] Create a network download operation `*`
- [ ] Create a network upload operation `*`
- [ ] Ability to restore uncompleted network operations `*`

> `*` Currently, `URLSession.shared` property is not yet implemented on Linux, also `QualityOfService` property is not directly supported on Linux, since there are not qos class promotions available outside of darwin targets.

Requirements
============

| **Swift** | **Xcode** | **Queuer**    | **iOS** | **macOS** | **tvOS** | **watchOS** | **Linux** |
|-----------|-----------|---------------|---------|-----------|----------|-------------|-----------|
| 3.1...3.2 | 8.3...9.0 | 1.0.0...1.1.0 | 8.0+    | 10.10     | 9.0      | 2.0+        | ![✓] `*`  |
| 4.0       | 9.0       | 1.2.1         | 8.0+    | 10.10     | 9.0      | 2.0+        | ![✓] `*`  |

> `*` Currently, `URLSession.shared` property is not yet implemented on Linux, also `QualityOfService` property is not directly supported on Linux, since there are not qos class promotions available outside of darwin targets.

Installing
==========

See [Requirements](https://github.com/FabrizioBrancati/Queuer#requirements) section to check Swift, Xcode, Queuer and OS versions.

### Manual
- Open and build the framework from the project (**Queuer.xcodeproj**)
- Import Queuer.framework into your project
- Import the framework with ```import Queuer```
- Enjoy!

### CocoaPods
- Create a **Podfile** in your **project directory** and write into:

    ```ruby
    platform :ios, '8.0'
    xcodeproj 'Project.xcodeproj'
    use_frameworks!

    pod 'Queuer'
    ```
- Change **"Project"**  with your **real project name**
- Open **Terminal**, go to your **project directory** and type: ```pod install```
- Import the framework with ```import Queuer```
- Enjoy!

### Carthage
- Create a **Cartfile** in your **project directory** and write into:

    ```ruby
    github "FabrizioBrancati/Queuer"
    ```
- Open **Terminal**, go to **project directory** and type: ```carthage update```
- **Include the created Framework** in your project
- **Add Build Phase** with the following contents:

    ```sh
    /usr/local/bin/carthage copy-frameworks
    ```

    and add the paths to the Queuer framework under **Input Files**

    ```sh
    $(SRCROOT)/Carthage/Build/iOS/Queuer.framework
    ```
    This script works around an [App Store submission bug](http://www.openradar.me/radar?id=6409498411401216) triggered by universal binaries and ensures that necessary bitcode-related files are copied when archiving
- Import the framework with ```import Queuer```
- Enjoy!

### Swift Package Manager
- Create a **Package.swift** file in your **project directory** and write into:

    ```swift
    import PackageDescription

    let package = Package(
        name: "Project",
        products: [
            .executable(name: "Project", targets: ["Project"])
        ],
        dependencies: [
            .package(url: "https://github.com/FabrizioBrancati/Queuer.git", .upToNextMajor(from: "1.0.0"))
        ],
        targets: [
            .target(name: "Project", dependencies: ["Queuer"])
        ]
    )
    ```
- Change **"Project"**  with your **real project name**
- Open **Terminal**, go to **project directory** and type: ```swift build```
- Import the framework with ```import Queuer```
- Enjoy!

Usage
=====

### Shared Queuer

```swift
Queuer.shared.addOperation(operation)
```

### Custom Queue

```swift
let queue = Queuer(name: "MyCustomQueue")
```

You can even create a queue by defining the `maxConcurrentOperationCount` and the `qualityOfService` `*` properties:
```swift
let queue = Queuer(name: "MyCustomQueue", maxConcurrentOperationCount: Int.max, qualityOfService: .default)
```
> `*` Currently, `QualityOfService` property is not directly supported on Linux, since there are not qos class promotions available outside of darwin targets.

### Create an Operation Block
You have three methods to add an `Operation` block:

- Directly on the `queue`(or `Queuer.shared`):
    ```swift
    queue.addOperation {
        /// Your task here
    }
    ```

- Creating a `ConcurrentOperation` with a block:
    ```swift
    let concurrentOperation = ConcurrentOperation {
        /// Your task here
    }
    queue.addOperation(concurrentOperation)
    ```

- Creating a `SynchronousOperation` with a block:
    ```swift
    let synchronousOperation = SynchronousOperation {
        /// Your task here
    }
    queue.addOperation(concurrentOperation)
    ```

> We will see how `ConcurrentOperation` and `SynchronousOperation` works later.

### Chained Operations
Chained Operations are operations that add a dependency each other.<br>
They follow the given array order, for example: `[A, B, C] = A -> B -> C -> completionBlock`.
```swift
let concurrentOperation1 = ConcurrentOperation {
    /// Your task 1 here
}
let concurrentOperation2 = ConcurrentOperation {
    /// Your task 2 here
}
queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
    /// Your completion task here
}
```

### Queue States
- Cancel all operations in queue:
    ```swift
    queue.cancelAll()
    ```
- Pause queue:
    ```swift
    queue.pause()
    ```
    > By calling `pause()` you will not be sure that every operation will be paused.
      If the Operation is already started it will not be on pause until it's a custom Operation that overrides `pause()` function or is a `RequestOperation`.

- Resume queue:
    ```swift
    queue.resume()
    ```
    > To have a complete `pause` and `resume` states you must create a custom Operation that overrides `pause()` and `resume()` function or use a `RequestOperation`.

- Wait until all operations are finished:
    ```swift
    queue.waitUntilAllOperationsAreFinished()
    ```
    > This function means that the queue will blocks the current thread until all operations are finished.

### Asynchronous Operation
`ConcurrentOperation` is a class created to be subclassed.
It allows synchronous and asynchronous tasks, has a pause and resume states, can be easily added to a queue and can be created with a block.

You can create your custom `ConcurrentOperation` by subclassing it.<br>
You must override `execute()` function and call the `finish()` function inside it, when the task has finished its job to notify the queue.<br>
Look at [RequestOperation.swift](https://github.com/FabrizioBrancati/Queuer/blob/master/Sources/Queuer/RequestOperation.swift) if you are looking for an example.

For convenience it has an `init` function with a completion block:
```swift
let concurrentOperation = ConcurrentOperation {
    /// Your task here
}
concurrentOperation.addToQueue(queue)
```

### Synchronous Operation
There are three methods to create synchronous tasks or even queue:
- Setting `maxConcurrentOperationCount` of the queue to `1`.<br>
  By setting that property to `1` you will be sure that only one task at time will be executed.
- Using a `Semaphore` and waiting until a task has finished its job.
- Using a `SynchronousOperation`.<br>
  It's a subclass of `ConcurrentOperation` that handles synchronous tasks.<br>
  It's not awesome as it seems to be and is always better to create an asynchronous task, but some times it may be useful.

For convenience it has an `init` function with a completion block:
```swift
let synchronousOperation = SynchronousOperation {
  /// Your task here
}
synchronousOperation.addToQueue(queue)
```

### Semaphore
A `Semaphore` is a struct that uses the GDC's `DispatchSemaphore` to create a semaphore on the function and wait until it finish its job.<br>
I recommend you to use a `defer { semaphore.continue() }` right after the `Semaphore` creation and `wait()` call.

```swift
let semaphore = Semaphore()
semaphore.wait()
defer { semaphore.continue() }
/// Your task here
```

It's more useful if used inside an asynchronous task:
```swift
let concurrentOperation = ConcurrentOperation {
    /// Your task here
    semaphore.continue()
}
concurrentOperation.addToQueue(queue)
semaphore.wait()
```

### Request Operation `*`
`RequestOperation` allows you to easily create a network request and add it to a queue:
```swift
let requestOperation: RequestOperation = RequestOperation(url: self.testAddress) { success, response, data, error in

}
requestOperation.addToQueue(queue)
```
Allowed parameters in `RequestOperation` `init` function:
- `url` is a `String` representing the request URL
- `query` is `Dictionary` representing the request query parameters to be added to the `url` with `?` and `&` characters
- `timeout` is the request timeout
- `method` is the request method, you can choose to one of: `connect`, `delete`, `get`, `head`, `options`, `patch`, `post` and `put`
- `cachePolicy` is the request cache policy, referrer to [CachePolicy documentation](https://developer.apple.com/documentation/foundation/nsurlrequest.cachepolicy)
- `headers` is a `Dictionary` representing the request headers
- `body` is a `Data` representing the request body
- `completionHandler` is the request response handler

Response handler variables:
- `success` is a `Bool` indicating if the request was successful.
  It's successful if its status is between 200 and 399, it wasn't cancelled and did't get any other network error.
- `respose` is an `HTTPURLResponse` instance.
  It contains all the response headers and the status code.
  May be `nil`.
- `data` is a `Data` instance with the request body.
  You must convert, to a JSON or String in example, it in order to use.
  May be `nil`.
- `error` is an `Error` instance with the request error.
  May be `nil`.

It can be `pause`d, `resume`d, `cancel`led and chained with other `Operation`s.

> `*` Currently, `URLSession.shared` property is not yet implemented on Linux.

Documentation
=============

### [Documentation]
100% Documented

Changelog
=========

To see what has changed in recent versions of Queuer, see the **[CHANGELOG.md](https://github.com/FabrizioBrancati/Queuer/blob/master/CHANGELOG.md)** file.

Communication
=============

- If you need help, open an issue.
- If you found a bug, open an issue.
- If you have a feature request, open an issue.
- If you want to contribute, see [Contributing](https://github.com/FabrizioBrancati/Queuer#contributing) section.

Contributing
============

See [CONTRIBUTING.md](https://github.com/FabrizioBrancati/Queuer/blob/master/.github/CONTRIBUTING.md) file.

Author
======

**Fabrizio Brancati**

[Website: https://www.fabriziobrancati.com](https://www.fabriziobrancati.com)
<br>
[Email: fabrizio.brancati@gmail.com](mailto:fabrizio.brancati@gmail.com)

License
=======

Queuer is available under the MIT license. See the **[LICENSE](https://github.com/FabrizioBrancati/Queuer/blob/master/LICENSE)** file for more info.

[Documentation]: https://github.fabriziobrancati.com/documentation/Queuer/
[✓]: https://github.fabriziobrancati.com/queuer/resources/check.png
