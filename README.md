# Queuer

[![GitHub Release](https://img.shields.io/github/v/release/FabrizioBrancati/Queuer?label=Release)](https://swiftpackageindex.com/FabrizioBrancati/Queuer)
[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FFabrizioBrancati%2FQueuer%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/FabrizioBrancati/Queuer)
[![Swift Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FFabrizioBrancati%2FQueuer%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/FabrizioBrancati/Queuer)

## Features

Queuer is a queue manager, built on top of [OperationQueue](https://developer.apple.com/documentation/foundation/operationqueue) and [Dispatch](https://developer.apple.com/documentation/dispatch) (aka GCD). It allows you to create any asynchronous and synchronous task easily, all managed by a queue, with just a few lines.

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
- [ ] Throttling between each automatic operation retry
- [ ] Data layer between operations

## Requirements

| **Swift**  | **Queuer**    | **iOS** | **macOS**  | **macCatalyst** | **tvOS**  | **watchOS** | **visionOS** | **Linux** |
|------------|---------------|---------|------------|-----------------|-----------|-------------|--------------|-----------|
| 3.1...3.2  | 1.0.0...1.1.0 | 8.0+    | 10.10+     |                 | 9.0+      | 2.0+        |              | ✅        |
| 4.0        | 1.3.0         | 8.0+    | 10.10+     |                 | 9.0+      | 2.0+        |              | ✅        |
| 4.1        | 1.3.1...1.3.2 | 8.0+    | 10.10+     |                 | 9.0+      | 2.0+        |              | ✅        |
| 4.2        | 2.0.0...2.0.1 | 8.0+    | 10.10+     |                 | 9.0+      | 3.0+        |              | ✅        |
| 5.0...5.10 | 2.1.0...2.2.0 | 8.0+    | 10.10+     |                 | 9.0+      | 3.0+        |              | ✅        |
| 5.9...5.10 | 3.0.0         | 12.0+   | 10.13+     | 13.0+           | 12.0+     | 4.0+        | 1.0+         | ✅        |

## Installing

See [Requirements](https://github.com/FabrizioBrancati/Queuer#requirements) section to check Swift, Xcode, Queuer and OS versions.

In your `Package.swift` Swift Package Manager manifest, add the following dependency to your `dependencies` argument:

```swift
.package(url: "https://github.com/FabrizioBrancati/Queuer.git", from: "3.0.0"),
```

Add the dependency to any targets you've declared in your manifest:

```swift
.target(
    name: "MyTarget", 
    dependencies: [
        .product(name: "Queuer", package: "Queuer"),
    ]
),
```

## Usage

- [Shared Queuer](https://github.com/FabrizioBrancati/Queuer#shared-queuer)
- [Custom Queue](https://github.com/FabrizioBrancati/Queuer#custom-queue)
- [Create an Operation Block](https://github.com/FabrizioBrancati/Queuer#create-an-operation-block)
- [Chained Operations](https://github.com/FabrizioBrancati/Queuer#chained-operations)
- [Group Oprations](https://github.com/FabrizioBrancati/Queuer#group-operations)
- [Queue States](https://github.com/FabrizioBrancati/Queuer#queue-states)
- [Asynchronous Operation](https://github.com/FabrizioBrancati/Queuer#asynchronous-operation)
- [Synchronous Operation](https://github.com/FabrizioBrancati/Queuer#synchronous-operation)
- [Automatically Retry an Operation](https://github.com/FabrizioBrancati/Queuer#automatically-retry-an-operation)
- [Manually Retry an Operation](https://github.com/FabrizioBrancati/Queuer#manually-retry-an-operation)
- [Scheduler](https://github.com/FabrizioBrancati/Queuer#scheduler)
- [Semaphore](https://github.com/FabrizioBrancati/Queuer#semaphore)

### Shared Queuer

Queuer offers a shared instance that you can use to add operations to a centralized queue:

```swift
Queuer.shared.addOperation(operation)
```

### Custom Queue

You can also create a custom queue:

```swift
let queue = Queuer(name: "MyCustomQueue")
```

You can even create a queue by defining the `maxConcurrentOperationCount` and the `qualityOfService` properties:

```swift
let queue = Queuer(name: "MyCustomQueue", maxConcurrentOperationCount: Int.max, qualityOfService: .default)
```

### Create an Operation Block

You have three methods to add an `Operation` block.

1. Directly on the `queue`(or `Queuer.shared`):

    ```swift
    queue.addOperation {
      /// Your task here
    }
    ```

2. Creating a `ConcurrentOperation` with a block:

    ```swift
    let concurrentOperation = ConcurrentOperation { _ in
        /// Your task here
    }
    queue.addOperation(concurrentOperation)
    ```

3. Creating a `SynchronousOperation` with a block:

    ```swift
    let synchronousOperation = SynchronousOperation { _ in
        /// Your task here
    }
    queue.addOperation(synchronousOperation)
    ```

> [!NOTE]
> We will see how `ConcurrentOperation` and `SynchronousOperation` works later.

### Chained Operations

Chained Operations are `Operation`s that add a dependency each other.

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

### Group Operations

Group Operations are `Operation`s that handles a group of `Operation`s with a completion handler.

Allows the execution of a block of `Operation`s with a completion handler that will be called once all the operations are finished, for example: `[A -> [[B & C & D] -> completionHandler] -> E] -> completionHandler`.
It should usually be used with a [Chained Opetation](https://github.com/FabrizioBrancati/Queuer#chained-operations).

```swift
let groupOperationA = GroupOperation(
    [
        ConcurrentOperation { _ in
            /// Your task A here
        },
        ConcurrentOperation { _ in
            /// Your task B here
        }
    ]
)

let concurrentOperationC = ConcurrentOperation { _ in
    /// Your task C here
}

queue.addChainedOperations([groupOperationA, concurrentOperationC]) {
    /// Your completion task here
}
```

In this case the output will be the following one: `[[A & B -> completionHandler] -> C] -> completionHandler`.

### Queue States

There are a few method to handle the queue states.

1. Cancel all `Operation`s in a queue:

    ```swift
    queue.cancelAll()
    ```

2. Pause a queue:

    ```swift
    queue.pause()
    ```

> [!WARNING]
> By calling `pause()` you will not be sure that every `Operation` will be paused. If the `Operation` is already started it will not be on pause until it's a custom `Operation` that overrides `pause()` function.

3. Resume a queue:

    ```swift
    queue.resume()
    ```

> [!WARNING]
> To have a complete `pause` and `resume` states you must create a custom `Operation` that overrides `pause()` and `resume()` function.

4. Wait until all `Operation`s are finished:

    ```swift
    queue.waitUntilAllOperationsAreFinished()
    ```

> [!IMPORTANT]
> This function means that the queue will blocks the current thread until all `Operation`s are finished.

### Asynchronous Operation

`ConcurrentOperation` is a class created to be subclassed.
It allows synchronous and asynchronous tasks, has a pause and resume states, can be easily added to a queue and can be created with a block.

You can create your custom `ConcurrentOperation` by subclassing it.

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

1. Setting `maxConcurrentOperationCount` of the queue to `1`. By setting that property to `1` you will be sure that only one task at time will be executed.

2. Using a `Semaphore` and waiting until a task has finished its job.

3. Using a `SynchronousOperation`. It's a subclass of `ConcurrentOperation` that handles synchronous tasks. It's not awesome as it seems to be and is always better to create an asynchronous task, but some times it may be useful.

For convenience it has an `init` function with a completion block:

```swift
let synchronousOperation = SynchronousOperation { _ in
  /// Your task here
}
synchronousOperation.addToQueue(queue)
```

### Automatically Retry an Operation

An `Operation` is passed to every closure, with it you can set and handle the retry feature.

By default the retry feature is disabled, to enable it simply set the `success` property to `false`. With `success` to `false` the `Operation` will retry until reaches `maximumRetries` property value. To let the `Operation` know when everything is ok, you must set `success` to `true`.

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

You can manually retry an `Operation` when you think that the execution will be successful.

An `Operation` is passed to every closure, with it you can set and handle the retry feature.

By default the manual retry feature is disabled, to enable it simply set the `manualRetry` property to `true`, you must do this outside of the execution closure. You must also set `success` to `true` or `false` to let the `Operation` know when is everything ok, like the automatic retry feature.

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
    /// Your task here
}
```

With `timer` property you can access to all `DispatchSourceTimer` properties and functions, like `cancel()`:

```swift
schedule.timer.cancel()
```

### Semaphore

A `Semaphore` is a struct that uses the GCD's `DispatchSemaphore` to create a semaphore on the function and wait until it finish its job.

> [!TIP]
> Is recommend to use a `defer { semaphore.continue() }` right after the `Semaphore` creation and `wait()` call.

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

## Changelog

To see what has changed in recent versions of Queuer, see the **[CHANGELOG.md](https://github.com/FabrizioBrancati/Queuer/blob/main/CHANGELOG.md)** file.

## Communication

- If you need help, open an issue.
- If you found a bug, open an issue.
- If you have a feature request, open an issue.
- If you want to contribute, see [Contributing](https://github.com/FabrizioBrancati/Queuer#contributing) section.

## Contributing

See [CONTRIBUTING.md](https://github.com/FabrizioBrancati/Queuer/blob/main/.github/CONTRIBUTING.md) file.

## License

Queuer is available under the MIT license. See the **[LICENSE](https://github.com/FabrizioBrancati/Queuer/blob/main/LICENSE)** file for more info.
