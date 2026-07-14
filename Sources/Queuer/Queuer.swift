//
//  Queuer.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2024 Fabrizio Brancati
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

/// Queuer class.
/// `@unchecked` since the underlying `OperationQueue` is thread safe,
/// but not marked as `Sendable` on every supported platform.
public final class Queuer: @unchecked Sendable {
    /// Shared Queuer.
    public static let shared = Queuer(name: "Queuer")

    /// Queuer `OperationQueue`.
    public let queue = OperationQueue()

    /// Total `Operation` count in queue.
    public var operationCount: Int {
        return queue.operationCount
    }

    /// `Operation`s currently in queue.
    public var operations: [Operation] {
        return queue.operations
    }

    /// The default service level to apply to `Operation`s executed using the queue.
    public var qualityOfService: QualityOfService {
        get {
            return queue.qualityOfService
        }
        set {
            queue.qualityOfService = newValue
        }
    }

    /// Returns if the queue is executing or is in pause.
    /// Call `resume()` to make it running.
    /// Call `pause()` to make to pause it.
    public var isExecuting: Bool {
        return !queue.isSuspended
    }

    /// Define the max concurrent `Operation`s count.
    public var maxConcurrentOperationCount: Int {
        get {
            return queue.maxConcurrentOperationCount
        }
        set {
            queue.maxConcurrentOperationCount = newValue
        }
    }

    /// Creates a new queue.
    ///
    /// - Parameters:
    ///   - name: Custom queue name.
    ///   - maxConcurrentOperationCount: The max concurrent `Operation`s count.
    ///   - qualityOfService: The default service level to apply to `Operation`s executed using the queue.
    public init(name: String, maxConcurrentOperationCount: Int = OperationQueue.defaultMaxConcurrentOperationCount, qualityOfService: QualityOfService = .default) {
        queue.name = name
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.qualityOfService = qualityOfService
    }

    /// Cancel all `Operation`s in queue.
    @available(*, deprecated, message: "Use `cancel()` instead.")
    public func cancelAll() {
        cancel()
    }

    /// Cancel all `Operation`s in queue.
    public func cancel() {
        queue.cancelAllOperations()
    }

    /// Pause all `Operation`s in queue.
    public func pause() {
        queue.isSuspended = true

        for operation in queue.operations {
            if let concurrentOperation = operation as? ConcurrentOperation {
                concurrentOperation.pause()
            }
        }
    }

    /// Resume all `Operation`s in queue.
    public func resume() {
        queue.isSuspended = false

        for operation in queue.operations {
            if let concurrentOperation = operation as? ConcurrentOperation {
                concurrentOperation.resume()
            }
        }
    }

    /// Blocks the current thread until all of the receiver’s queued and executing
    /// `Operation`s finish executing.
    /// - Returns: Returns the current `Queuer` instance.
    @discardableResult
    public func waitUntilAllOperationsAreFinished() -> Queuer {
        queue.waitUntilAllOperationsAreFinished()
        return self
    }
}

// MARK: - Queuer Operations and Chaining

/// `Queuer` extension with `Operation`s and chaining handling.
extension Queuer {
    /// Add an `Operation` to be executed asynchronously.
    ///
    /// - Parameter block: Block to be executed.
    public func addOperation(_ operation: @Sendable @escaping () -> Void) {
        queue.addOperation(operation)
    }

    /// Add an `Operation` to be executed asynchronously.
    ///
    /// - Parameter operation: `Operation` to be executed.
    public func addOperation(_ operation: Operation) {
        queue.addOperation(operation)
    }

    /// Add an Array of chained `Operation`s.
    ///
    /// Example:
    ///
    ///     [A, B, C] = A -> B -> C -> completionHandler
    ///
    /// - Parameters:
    ///   - operations: `Operation`s Array.
    ///   - completionHandler: Completion block to be executed when all `Operation`s
    ///                        are finished.
    public func addChainedOperations(_ operations: [Operation], completionHandler: (@Sendable () -> Void)? = nil) {
        for (index, operation) in operations.enumerated() {
            if index > 0 {
                operation.addDependency(operations[index - 1])
            }

            addOperation(operation)
        }

        guard let completionHandler = completionHandler else {
            return
        }

        guard !operations.isEmpty else {
            addCompletionHandler(completionHandler)
            return
        }

        /// The completion depends on every `Operation` of the chain directly.
        /// Depending on the last `Operation` currently in the queue would be racy:
        /// the chain could already be finished, or the last `Operation`
        /// could belong to someone else on a shared queue.
        let completionOperation = BlockOperation(block: completionHandler)
        for operation in operations {
            completionOperation.addDependency(operation)
        }
        addOperation(completionOperation)
    }

    /// Add an Array of chained `Operation`s.
    ///
    /// Example:
    ///
    ///     [A, B, C] = A -> B -> C -> completionHandler
    ///
    /// - Parameters:
    ///   - operations: `Operation`s Array.
    ///   - completionHandler: Completion block to be executed when all `Operation`s
    ///                        are finished.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func addChainedAsyncOperations(_ operations: [Operation], completionHandler: (@Sendable () async -> Void)? = nil) {
        for (index, operation) in operations.enumerated() {
            if index > 0 {
                operation.addDependency(operations[index - 1])
            }

            addOperation(operation)
        }

        guard let completionHandler = completionHandler else {
            return
        }

        guard !operations.isEmpty else {
            addAsyncCompletionHandler(completionHandler)
            return
        }

        /// The completion depends on every `Operation` of the chain directly.
        /// Depending on the last `Operation` currently in the queue would be racy:
        /// the chain could already be finished, or the last `Operation`
        /// could belong to someone else on a shared queue.
        let completionOperation = AsyncConcurrentOperation { _ in
            await completionHandler()
        }
        for operation in operations {
            completionOperation.addDependency(operation)
        }
        addOperation(completionOperation)
    }

    /// Add an Array of chained `Operation`s.
    ///
    /// Example:
    ///
    ///     [A, B, C] = A -> B -> C -> completionHandler
    ///
    /// - Parameters:
    ///   - operations: `Operation`s list.
    ///   - completionHandler: Completion block to be exectuted when all `Operation`s
    ///                        are finished.
    public func addChainedOperations(_ operations: Operation..., completionHandler: (@Sendable () -> Void)? = nil) {
        addChainedOperations(operations, completionHandler: completionHandler)
    }

    /// Add a completion block to the queue.
    /// The completion waits for every `Operation` currently in the queue.
    /// On an empty queue, the completion is executed right away.
    ///
    /// - Parameter completionHandler: Completion handler to be executed as last `Operation`.
    public func addCompletionHandler(_ completionHandler: @Sendable @escaping () -> Void) {
        let completionOperation = BlockOperation(block: completionHandler)
        /// Depending on every `Operation` guarantees the completion runs last,
        /// even on concurrent queues where the last added `Operation`
        /// is not necessarily the last to finish.
        /// Dependencies on already finished `Operation`s are immediately satisfied.
        for operation in operations where !operation.isFinished {
            completionOperation.addDependency(operation)
        }
        addOperation(completionOperation)
    }

    /// Adds a barrier block to the queue.
    /// The barrier waits for all the `Operation`s currently in the queue,
    /// and every `Operation` added afterwards waits for the barrier to finish.
    ///
    /// - Parameter completionHandler: Barrier block to be executed.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func addBarrier(_ completionHandler: @escaping @Sendable () -> Void) {
        queue.addBarrierBlock(completionHandler)
    }

    /// Add an async completion block to the queue.
    /// The completion waits for every `Operation` currently in the queue.
    /// On an empty queue, the completion is executed right away.
    ///
    /// - Parameter completionHandler: Async completion handler to be executed as last `Operation`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func addAsyncCompletionHandler(_ completionHandler: @Sendable @escaping () async -> Void) {
        let completionOperation = AsyncConcurrentOperation { _ in
            await completionHandler()
        }
        /// Depending on every `Operation` guarantees the completion runs last,
        /// even on concurrent queues where the last added `Operation`
        /// is not necessarily the last to finish.
        /// Dependencies on already finished `Operation`s are immediately satisfied.
        for operation in operations where !operation.isFinished {
            completionOperation.addDependency(operation)
        }
        addOperation(completionOperation)
    }
}
