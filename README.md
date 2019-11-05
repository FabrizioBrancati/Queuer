<p align="center">
<img src="Resources/Banner.png" alt="Queuer Banner">
</p>

[![Build Status](https://travis-ci.com/FabrizioBrancati/Queuer.svg?branch=master)](https://travis-ci.com/FabrizioBrancati/Queuer)
[![Coverage Status](https://coveralls.io/repos/github/FabrizioBrancati/Queuer/badge.svg?branch=master)](https://coveralls.io/github/FabrizioBrancati/Queuer?branch=master)
[![Documentation](https://github.fabriziobrancati.com/documentation/Queuer/badge.svg)](https://github.fabriziobrancati.com/documentation/Queuer/)
[![Swift Package Manager Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/Queuer.svg?style=flat)][Documentation]
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/FabrizioBrancati/Queuer/blob/master/LICENSE)
<br>
[![Maintainability](https://api.codeclimate.com/v1/badges/ce03faaf6abe697458ed/maintainability)](https://codeclimate.com/github/FabrizioBrancati/Queuer/maintainability)
[![codebeat badge](https://codebeat.co/badges/50844e60-f4f2-4f9f-a688-5ccc976b7c8c)](https://codebeat.co/projects/github-com-fabriziobrancati-queuer-master-9833cda0-af64-433d-a08a-cd0d50d6b579)
[![Language](https://img.shields.io/badge/language-Swift%205.0%20%7C%205.1-orange.svg)](https://swift.org/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-cc9c00.svg)][Documentation]

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
It allows you to create any asynchronous and synchronous task easily, all managed by a queue, with just a few lines.

Here is the list of all the features:
- [x] Works on all Swift compatible platforms (even Linux)
- [x] Easy to use
- [x] Well documented (100% documented)
- [x] Well tested (100% of code coverage)
- [x] Create an operation block
- [x] Create a single operation
- [x] Create chained operations
- [x] Manage a centralized queue
- [x] Create unlimited queue
- [x] Declare how many concurrent operation a queue can handle
- [x] Create semaphores
- [x] Create and handle schedules
- [x] Automatically or manually retry an operation
- [x] Ability to restore uncompleted operations
- [ ] Improve the state restoration feature
- [ ] Throttling between each automatic operation retry
- [ ] Data layer that every operation inside an `OperationQueue` can access

Requirements
============

| **Swift** | **Xcode**   | **Queuer**    | **iOS** | **macOS**  | **tvOS**  | **watchOS** | **Linux** |
|-----------|-------------|---------------|---------|------------|-----------|-------------|-----------|
| 3.1...3.2 | 8.3...9.0   | 1.0.0...1.1.0 | 8.0+    | 10.10+     | 9.0+      | 2.0+        | ![✓]      |
| 4.0       | 9.0...9.2   | 1.3.0         | 8.0+    | 10.10+     | 9.0+      | 2.0+        | ![✓]      |
| 4.1       | 9.3...9.4   | 1.3.1...1.3.2 | 8.0+    | 10.10+     | 9.0+      | 2.0+        | ![✓]      |
| 4.2       | 10.0...10.1 | 2.0.0...2.0.1 | 8.0+    | 10.10+     | 9.0+      | 3.0+        | ![✓]      |
| 5.0...5.1 | 10.2...11.2 | 2.1.0...2.1.1 | 8.0+    | 10.10+     | 9.0+      | 3.0+        | ![✓]      |

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

    Add the paths to the Queuer framework under **Input Files**

    ```sh
    $(SRCROOT)/Carthage/Build/iOS/Queuer.framework
    ```

    Add the paths to the copied frameworks to the **Output Files**

    ```sh
    $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/Queuer.framework
    ```

    This script works around an [App Store submission bug](http://www.openradar.me/radar?id=6409498411401216) triggered by universal binaries and ensures that necessary bitcode-related files are copied when archiving
- **(Optional)** Add Build Phase with the following contents

    ```sh
    /usr/local/bin/carthage outdated --xcode-warnings
    ```

    To automatically warn you when one of your dependencies is out of date
- Import the framework with ```import Queuer```
- Enjoy!

### Swift Package Manager
- Create a **Package.swift** file in your **project directory** and write into:

    ```swift
    // swift-tools-version:5.1
    import PackageDescription

    let package = Package(
        name: "Project",
        products: [
            .executable(name: "Project", targets: ["Project"])
        ],
        dependencies: [
            .package(url: "https://github.com/FabrizioBrancati/Queuer.git", .upToNextMajor(from: "2.0.0"))
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

- [Shared Queuer](https://github.com/FabrizioBrancati/Queuer#shared-queuer)
- [Custom Queue](https://github.com/FabrizioBrancati/Queuer#custom-queue)
- [Create an Operation Block](https://github.com/FabrizioBrancati/Queuer#create-an-operation-block)
- [Chained Operations](https://github.com/FabrizioBrancati/Queuer#chained-operations)
- [Queue States](https://github.com/FabrizioBrancati/Queuer#queue-states)
- [Asynchronous Operation](https://github.com/FabrizioBrancati/Queuer#asynchronous-operation)
- [Synchronous Operation](https://github.com/FabrizioBrancati/Queuer#synchronous-operation)
- [Automatically Retry an Operation](https://github.com/FabrizioBrancati/Queuer#automatically-retry-an-operation)
- [Manually Retry an Operation](https://github.com/FabrizioBrancati/Queuer#manually-retry-an-operation)
- [Scheduler](https://github.com/FabrizioBrancati/Queuer#scheduler)
- [Semaphore](https://github.com/FabrizioBrancati/Queuer#semaphore)
- [Queue State Restoration (Beta)](https://github.com/FabrizioBrancati/Queuer#queue-state-restoration-beta)

### Shared Queuer

```swift
Queuer.shared.addOperation(operation)
```

### Custom Queue

```swift
let queue = Queuer(name: "MyCustomQueue")
```

You can even create a queue by defining the `maxConcurrentOperationCount` and the `qualityOfService` properties:
```swift
let queue = Queuer(name: "MyCustomQueue", maxConcurrentOperationCount: Int.max, qualityOfService: .default)
```

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
    let concurrentOperation = ConcurrentOperation { _ in
        /// Your task here
    }
    queue.addOperation(concurrentOperation)
    ```

- Creating a `SynchronousOperation` with a block:
    ```swift
    let synchronousOperation = SynchronousOperation { _ in
        /// Your task here
    }
    queue.addOperation(synchronousOperation)
    ```

> We will see how `ConcurrentOperation` and `SynchronousOperation` works later.

### Chained Operations
Chained Operations are `Operation`s that add a dependency each other.<br>
They follow the given array order, for example: `[A, B, C] = A -> B -> C -> completionBlock`.
```swift
let concurrentOperationA = ConcurrentOperation { _ in
    /// Your task A here
}
let concurrentOperationB = ConcurrentOperation { _ in
    /// Your task B here
}
queue.addChainedOperations([concurrentOperationA, concurrentOperationB]) {
    /// Your completion task here
}
```

You can also add a `completionHandler` after the queue creation with:
```swift
queue.addCompletionHandler {
    /// Your completion task here
}
```

### Queue States
- Cancel all `Operation`s in queue:
    ```swift
    queue.cancelAll()
    ```
- Pause queue:
    ```swift
    queue.pause()
    ```
    > By calling `pause()` you will not be sure that every `Operation` will be paused.<br>
    If the `Operation` is already started it will not be on pause until it's a custom `Operation` that overrides `pause()` function.

- Resume queue:
    ```swift
    queue.resume()
    ```
    > To have a complete `pause` and `resume` states you must create a custom `Operation` that overrides `pause()` and `resume()` function.

- Wait until all `Operation`s are finished:
    ```swift
    queue.waitUntilAllOperationsAreFinished()
    ```
    > This function means that the queue will blocks the current thread until all `Operation`s are finished.

### Asynchronous Operation
`ConcurrentOperation` is a class created to be subclassed.
It allows synchronous and asynchronous tasks, has a pause and resume states, can be easily added to a queue and can be created with a block.

You can create your custom `ConcurrentOperation` by subclassing it.<br>
You must override `execute()` function and call the `finish()` function inside it, when the task has finished its job to notify the queue.

For convenience it has an `init` function with a completion block:
```swift
let concurrentOperation = ConcurrentOperation { _ in
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
let synchronousOperation = SynchronousOperation { _ in
  /// Your task here
}
synchronousOperation.addToQueue(queue)
```

### Automatically Retry an Operation
An `Operation` is passed to every closure, with it you can set and handle the retry feature.<br>
By default the retry feature is disabled, to enable it simply set the `success` property to `false`. With `success` to `false` the `Operation` will retry until reaches `maximumRetries` property value. To let the `Operation` know when everything is ok, you must set `success` to `true`.<br>
With `currentAttempt` you can know at which attempt the `Operation` is.
```swift
let concurrentOperation = ConcurrentOperation { operation in
    /// Your task here
    if /* Successful */ {
      operation.success = true
    } else {
      operation.success = false
    }
}
```

### Manually Retry an Operation
You can manually retry an `Operation` when you think that the execution will be successful.<br>
An `Operation` is passed to every closure, with it you can set and handle the retry feature.<br>
By default the manual retry feature is disabled, to enable it simply set the `manualRetry` property to `true`, you must do this outside of the execution closure. You must also set `success` to `true` or `false` to let the `Operation` know when is everything ok, like the automatic retry feature.<br>
To let the `Operation` retry your execution closure, you have to call the `retry()` function. If the `retry()` is not called, you may block the entire queue. Be sure to call it at least `maximumRetries` times, it is not a problem if you call `retry()` more times than is needed, your execution closure will not be executed more times than the `maximumRetries` value.
```swift
let concurrentOperation = ConcurrentOperation { operation in
    /// Your task here
    if /* Successful */ {
      operation.success = true
    } else {
      operation.success = false
    }
}
concurrentOperation.manualRetry = true
/// Later on your code
concurrentOperation.retry()
```

### Scheduler
A `Scheduler` is a struct that uses the GDC's `DispatchSourceTimer` to create a timer that can execute functions with a specified interval and quality of service.

```swift
let schedule = Scheduler(deadline: .now(), repeating: .seconds(1)) {
    /// Your task here
}
```

You can even create a `Scheduler` without the handler and set it later:
```swift
var schedule = Scheduler(deadline: .now(), repeating: .seconds(1))
schedule.setHandler {
    /// Your task here.
}
```

With `timer` property you can access to all `DispatchSourceTimer` properties and functions, like `cancel()`:
```swift
schedule.timer.cancel()
```

### Semaphore
A `Semaphore` is a struct that uses the GCD's `DispatchSemaphore` to create a semaphore on the function and wait until it finish its job.<br>
I recommend you to use a `defer { semaphore.continue() }` right after the `Semaphore` creation and `wait()` call.

```swift
let semaphore = Semaphore()
semaphore.wait()
defer { semaphore.continue() }
/// Your task here
```

You can even set a custom timeout, default is `.distantFuture`:
```swift
semaphore.wait(DispatchTime(uptimeNanoseconds: 1_000_000_000))
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

### Queue State Restoration (Beta)
To enable the Queue Restoration feature you must use `ConcurrentOperation` with a unique (non-nil) `name` property.
Currently this feature allows you to save the current state (`OperationState`s) of your queue, like: `name`, `progress` and `dependencies`.<br>
The `progress` property allows to save the current state of the `Operation` progress. Update it constantly during the `Operation` execution.<br>
Call `Queuer.state(of: OperationQueue)` or `operationQueue.state()` to get the `QueueStateList` aka: Array of `OperationState`s.<br>
It's up to you save and retrieve this list, and create the queue correctly.

Documentation
=============

Jazzy Generated [Documentation] - 100% Documented

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
[✓]: Resources/Check.png
