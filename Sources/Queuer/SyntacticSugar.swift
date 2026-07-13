//
//  SyntacticSugar.swift
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

/// `Queuer` extension with syntactic sugar.
/// Every function returns the `Queuer` instance, so the calls can be chained.
public extension Queuer {
    /// Adds an `Operation` to be executed asynchronously.
    ///
    /// - Parameter operation: `Operation` to be executed.
    /// - Returns: Returns the current `Queuer` instance.
    @discardableResult
    func add(_ operation: Operation) -> Queuer {
        addOperation(operation)
        return self
    }

    /// Sets the max concurrent `Operation`s count.
    ///
    /// - Parameter count: The max concurrent `Operation`s count.
    /// - Returns: Returns the current `Queuer` instance.
    @discardableResult
    func maxConcurrentOperationCount(_ count: Int) -> Queuer {
        maxConcurrentOperationCount = count
        return self
    }

    /// Sets the default service level to apply to `Operation`s executed using the queue.
    ///
    /// - Parameter quality: The default service level.
    /// - Returns: Returns the current `Queuer` instance.
    @discardableResult
    func qualityOfService(_ quality: QualityOfService) -> Queuer {
        qualityOfService = quality
        return self
    }

    /// Adds a completion block to the queue.
    /// The completion block waits for the last `Operation` currently in the queue.
    ///
    /// - Parameter completion: Completion block to be executed.
    /// - Returns: Returns the current `Queuer` instance.
    @discardableResult
    func completion(_ completion: @escaping () -> Void) -> Queuer {
        addCompletionHandler(completion)
        return self
    }

    /// Adds a list of chained `Operation`s.
    ///
    /// Example:
    ///
    ///     [A, B, C] = A -> B -> C
    ///
    /// - Parameter operations: `Operation`s list.
    /// - Returns: Returns the current `Queuer` instance.
    @discardableResult
    func chained(_ operations: Operation...) -> Queuer {
        addChainedOperations(operations)
        return self
    }

    /// Adds a list of chained `ConcurrentOperation`s created from the given execution blocks.
    ///
    /// Example:
    ///
    ///     [A, B, C] = A -> B -> C
    ///
    /// - Parameter blocks: Execution blocks list.
    /// - Returns: Returns the current `Queuer` instance.
    @discardableResult
    func chained(_ blocks: ((_ operation: ConcurrentOperation) -> Void)...) -> Queuer {
        addChainedOperations(blocks.map { ConcurrentOperation(executionBlock: $0) })
        return self
    }

    /// Adds a `ConcurrentOperation` with the given execution block.
    ///
    /// - Parameter block: Execution block.
    /// - Returns: Returns the current `Queuer` instance.
    @discardableResult
    func concurrent(_ block: @escaping (_ operation: ConcurrentOperation) -> Void) -> Queuer {
        addOperation(ConcurrentOperation(executionBlock: block))
        return self
    }

    /// Adds a `ConcurrentOperation` with the given execution block and maximum allowed retries.
    ///
    /// - Parameters:
    ///   - retries: Maximum allowed retries.
    ///   - block: Execution block.
    /// - Returns: Returns the current `Queuer` instance.
    @discardableResult
    func concurrent(retries: Int, _ block: @escaping (_ operation: ConcurrentOperation) -> Void) -> Queuer {
        let operation = ConcurrentOperation(executionBlock: block)
        operation.maximumRetries = retries
        addOperation(operation)
        return self
    }

    /// Adds a `GroupOperation` with the given `ConcurrentOperation`s.
    ///
    /// - Parameter operations: `ConcurrentOperation`s list to be executed as a group.
    /// - Returns: Returns the current `Queuer` instance.
    @discardableResult
    func group(_ operations: ConcurrentOperation...) -> Queuer {
        addOperation(GroupOperation(operations))
        return self
    }

    /// Adds a barrier block to the queue.
    /// The barrier waits for all the `Operation`s currently in the queue,
    /// and every `Operation` added afterwards waits for the barrier to finish.
    ///
    /// - Parameter block: Barrier block to be executed.
    /// - Returns: Returns the current `Queuer` instance.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @discardableResult
    func barrier(_ block: @escaping @Sendable () -> Void) -> Queuer {
        addBarrier(block)
        return self
    }

    /// Adds an `Operation` that waits the given time without blocking a thread.
    ///
    /// - Parameters:
    ///   - time: Time to wait.
    ///   - tolerance: Wait tolerance.
    ///   - clock: Clock to be used, default is `ContinuousClock`.
    /// - Returns: Returns the current `Queuer` instance.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    @discardableResult
    func asyncWait<C>(_ time: C.Instant.Duration, tolerance: C.Instant.Duration? = nil, clock: C = ContinuousClock()) -> Queuer where C: Clock {
        let operation = ConcurrentOperation()
        operation.manualFinish = true
        operation.manualRetry = true
        /// Using the block's `operation` parameter instead of the captured variable
        /// avoids a retain cycle between the `Operation` and its `executionBlock`.
        operation.executionBlock { operation in
            Task {
                try? await Task.sleep(for: time, tolerance: tolerance, clock: clock)
                operation.finish()
            }
        }
        add(operation)
        return self
    }

    /// Adds an `Operation` that waits the given time by blocking its queue thread.
    ///
    /// - Parameter time: Time to wait.
    /// - Returns: Returns the current `Queuer` instance.
    @discardableResult
    func syncWait(_ time: TimeInterval) -> Queuer {
        let operation = ConcurrentOperation { _ in
            Thread.sleep(forTimeInterval: time)
        }
        add(operation)
        return self
    }
}

/// `ConcurrentOperation` extension with syntactic sugar.
/// Every function returns the `ConcurrentOperation` instance, so the calls can be chained.
public extension ConcurrentOperation {
    /// Sets the manual finish state.
    ///
    /// - Parameter manualFinish: Whether the `Operation` must be manually finished.
    /// - Returns: Returns the current `ConcurrentOperation` instance.
    @discardableResult
    func manualFinish(_ manualFinish: Bool = true) -> ConcurrentOperation {
        self.manualFinish = manualFinish
        return self
    }

    /// Sets the manual retry state.
    ///
    /// - Parameter manualRetry: Whether the `Operation` must be manually retried.
    /// - Returns: Returns the current `ConcurrentOperation` instance.
    @discardableResult
    func manualRetry(_ manualRetry: Bool = true) -> ConcurrentOperation {
        self.manualRetry = manualRetry
        return self
    }

    /// Sets the execution block.
    ///
    /// - Parameter block: Execution block.
    /// - Returns: Returns the current `ConcurrentOperation` instance.
    @discardableResult
    func executionBlock(_ block: @escaping (_ operation: ConcurrentOperation) -> Void) -> ConcurrentOperation {
        executionBlock = block
        return self
    }

    /// Sets the maximum allowed retries.
    ///
    /// - Parameter retries: Maximum allowed retries.
    /// - Returns: Returns the current `ConcurrentOperation` instance.
    @discardableResult
    func maximumRetries(_ retries: Int) -> ConcurrentOperation {
        maximumRetries = retries
        return self
    }

    /// Sets the `Operation` name.
    ///
    /// - Parameter name: `Operation` name.
    /// - Returns: Returns the current `ConcurrentOperation` instance.
    @discardableResult
    func name(_ name: String) -> ConcurrentOperation {
        self.name = name
        return self
    }

    /// Sets the execution priority in its queue.
    ///
    /// - Parameter priority: Execution priority.
    /// - Returns: Returns the current `ConcurrentOperation` instance.
    @discardableResult
    func queuePriority(_ priority: Operation.QueuePriority) -> ConcurrentOperation {
        self.queuePriority = priority
        return self
    }

    /// Sets the service level to apply to the `Operation`.
    ///
    /// - Parameter quality: The service level.
    /// - Returns: Returns the current `ConcurrentOperation` instance.
    @discardableResult
    func qualityOfService(_ quality: QualityOfService) -> ConcurrentOperation {
        self.qualityOfService = quality
        return self
    }

    /// Sets the block to be called when the `Operation` is paused.
    ///
    /// - Parameter block: Pause block.
    /// - Returns: Returns the current `ConcurrentOperation` instance.
    @discardableResult
    func onPause(_ block: @escaping (_ operation: ConcurrentOperation) -> Void) -> ConcurrentOperation {
        self.onPause = block
        return self
    }

    /// Sets the block to be called when the `Operation` is resumed.
    ///
    /// - Parameter block: Resume block.
    /// - Returns: Returns the current `ConcurrentOperation` instance.
    @discardableResult
    func onResume(_ block: @escaping (_ operation: ConcurrentOperation) -> Void) -> ConcurrentOperation {
        self.onResume = block
        return self
    }

    /// Sets the block to be called when the `Operation` is canceled.
    ///
    /// - Parameter block: Cancel block.
    /// - Returns: Returns the current `ConcurrentOperation` instance.
    @discardableResult
    func onCancel(_ block: @escaping (_ operation: ConcurrentOperation) -> Void) -> ConcurrentOperation {
        self.onCancel = block
        return self
    }
}
