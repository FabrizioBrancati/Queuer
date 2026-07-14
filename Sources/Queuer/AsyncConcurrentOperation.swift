//
//  AsyncConcurrentOperation.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2026 Fabrizio Brancati
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

/// It allows asynchronous tasks based on async/await, has a pause and resume states,
/// can be easily added to a queue and can be created with an async throwing block.
///
/// A thrown error marks the attempt as failed, enabling the retry feature.
/// Canceling the `Operation` also cancels the `Task` running its execution block.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class AsyncConcurrentOperation: Operation, @unchecked Sendable {
    /// `Operation`'s execution block.
    public var executionBlock: ((_ operation: AsyncConcurrentOperation) async throws -> Void)?

    /// `Operation`'s pause block.
    /// This block is called when the `Operation` is paused.
    public var onPause: ((_ operation: AsyncConcurrentOperation) -> Void)?

    /// `Operation`'s resume block.
    /// This block is called when the `Operation` is resumed.
    public var onResume: ((_ operation: AsyncConcurrentOperation) -> Void)?

    /// `Operation`'s cancel block.
    /// This block is called when the `Operation` is canceled.
    public var onCancel: ((_ operation: AsyncConcurrentOperation) -> Void)?

    /// Lock that protects the retry state shared between threads.
    private let stateLock = NSLock()

    /// `Task` running the execution block, canceled together with the `Operation`,
    /// protected by the state lock.
    private var executionTask: Task<Void, Never>?

    /// Continuation parked while waiting for a manual `finish(success:)` call,
    /// protected by the state lock.
    private var finishContinuation: CheckedContinuation<Void, Never>?

    /// Set if the `Operation` is executing.
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }

    /// Set if the `Operation` is executing.
    override open var isExecuting: Bool {
        return _executing
    }

    /// Set if the `Operation` is finished.
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }

    /// Set if the `Operation` is finished.
    override open var isFinished: Bool {
        return _finished
    }

    /// The `Operation` manages its own state,
    /// its task always lives longer than the `start()` call.
    override open var isAsynchronous: Bool {
        return true
    }

    /// You should use `success` if you want the retry feature.
    /// Set it to `false` if the `Operation` has failed, otherwise `true`.
    /// Default is `true` to avoid retries.
    /// A thrown error sets it to `false` automatically.
    open var success: Bool {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _success
        }
        set {
            stateLock.lock()
            defer { stateLock.unlock() }
            _success = newValue
        }
    }

    /// `success` backing storage, protected by the state lock.
    private var _success = true

    /// Maximum allowed retries.
    /// Default are 3 retries.
    open var maximumRetries = 3

    /// Throttling between each automatic retry.
    /// The first attempt is never delayed.
    /// Default is 0, retries happen immediately.
    open var retryDelay: TimeInterval = 0

    /// Current retry attempt.
    open var currentAttempt: Int {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _currentAttempt
    }

    /// `currentAttempt` backing storage, protected by the state lock.
    private var _currentAttempt = 1

    /// Allows for manual retries.
    /// If set to `true`, `retry()` function must be manually called.
    /// Default is `false` to automatically retry.
    open var manualRetry = false

    /// Specify if the `Operation` should retry another time.
    internal var shouldRetry = true

    /// Manually control the `finish(success:)` call of the `Operation`.
    /// If set to `true` it is the developer's responsibility to call the `finish(success:)` method,
    /// either by passing `false` or `true` to the function.
    open var manualFinish = false

    /// Keep track of the last executed attempt.
    /// This avoids running the `executionBlock` more than once per retry.
    private var lastExecutedAttempt = 0

    /// Whether the `Operation` has been started by its queue, protected by the state lock.
    private var hasStarted = false

    /// Whether an attempt of the `executionBlock` is currently running, protected by the state lock.
    private var attemptInFlight = false

    /// Keep track of the `finish(success:)` terminal state, protected by the state lock.
    /// This makes `finish(success:)` idempotent.
    private var hasFinished = false

    /// Next action decided by the execution loop.
    private enum ExecutionAction {
        case exit
        case finishCanceled
        case runAttempt(attempt: Int)
        case waitForManualFinish
    }

    /// Creates the `Operation` with an async throwing execution block.
    ///
    /// - Parameters:
    ///   - name: Operation name.
    ///   - executionBlock: Async throwing execution block.
    public init(name: String? = nil, executionBlock: ((_ operation: AsyncConcurrentOperation) async throws -> Void)? = nil) {
        super.init()

        self.name = name
        self.executionBlock = executionBlock
    }

    /// Runs the given body while holding the state lock.
    /// `NSLock.lock()` cannot be called directly from asynchronous contexts,
    /// this synchronous helper provides scoped locking,
    /// and never suspends while holding the lock.
    private func withStateLock<T>(_ body: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return body()
    }

    /// Start the `Operation`.
    override open func start() {
        /// As required by the `Operation` contract, a canceled `Operation`
        /// must move directly to the finished state without executing.
        /// `OperationQueue` calls `start()` even on operations that were
        /// canceled before ever starting.
        guard !isCancelled else {
            stateLock.lock()
            hasFinished = true
            shouldRetry = false
            stateLock.unlock()

            _finished = true
            return
        }

        stateLock.lock()
        hasStarted = true
        stateLock.unlock()

        _executing = true

        /// The `Task` is created and stored while holding the lock,
        /// so a concurrent `cancel()` can never miss it.
        /// The task body never runs synchronously on this thread.
        stateLock.lock()
        executionTask = Task {
            await execute()
        }
        stateLock.unlock()
    }

    /// Retry function.
    /// It only works if `manualRetry` property has been set to `true`,
    /// and the `Operation` has already been started by its queue.
    open func retry() async {
        guard manualRetry else {
            return
        }

        /// Claim the current attempt while holding the lock, so concurrent
        /// `retry()` calls cannot run the same attempt more than once,
        /// and a never started, finished, or canceled `Operation` is left untouched.
        /// With `manualFinish` the attempt is not claimed, since `finish(success:)`
        /// is never called automatically and the attempt never advances.
        let claimed: Bool = withStateLock {
            guard hasStarted, !hasFinished, shouldRetry, !isCancelled, executionBlock != nil else {
                return false
            }

            if !manualFinish {
                guard lastExecutedAttempt != _currentAttempt else {
                    return false
                }

                lastExecutedAttempt = _currentAttempt
            }
            attemptInFlight = true
            return true
        }

        guard claimed else {
            return
        }

        await runAttempt()

        if !manualFinish {
            finish(success: success)
        }
    }

    /// Execute the `Operation`.
    /// If `executionBlock` is set, it will be executed.
    open func execute() async {
        guard executionBlock != nil else {
            /// An `Operation` without an execution block has nothing to execute,
            /// so it must finish right away, unless a manual finish is required.
            /// Otherwise it would occupy its queue forever.
            if !manualFinish {
                finish(success: success)
            }
            return
        }

        guard !manualRetry else {
            /// The first attempt is always executed,
            /// the following ones must be manually retried.
            await retry()
            return
        }

        while true {
            /// Claim the current attempt once, before executing the block.
            /// `finish(success:)` can be called from another thread while
            /// the block is being executed.
            let action: ExecutionAction = withStateLock {
                guard shouldRetry, !hasFinished else {
                    return .exit
                }

                guard !isCancelled else {
                    return .finishCanceled
                }

                guard lastExecutedAttempt != _currentAttempt else {
                    return .waitForManualFinish
                }

                lastExecutedAttempt = _currentAttempt
                attemptInFlight = true
                return .runAttempt(attempt: _currentAttempt)
            }

            switch action {
            case .exit:
                return
            case .finishCanceled:
                /// A canceled `Operation` must not retry another attempt.
                finish(success: success)
                return
            case let .runAttempt(attempt):
                /// Throttle automatic retries, the first attempt is never delayed.
                /// The cooperative cancellation interrupts the delay right away.
                if attempt > 1, retryDelay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))

                    guard !isCancelled else {
                        withStateLock { attemptInFlight = false }
                        finish(success: success)
                        return
                    }
                }

                await runAttempt()

                if !manualFinish {
                    finish(success: success)
                }
            case .waitForManualFinish:
                /// Wait for a manual `finish(success:)` call,
                /// suspending the task instead of spinning or blocking a thread.
                await waitForManualFinish()
            }
        }
    }

    /// Runs a single attempt of the execution block.
    /// A thrown error, including `CancellationError`, marks the attempt as failed.
    private func runAttempt() async {
        guard let executionBlock else {
            return
        }

        do {
            try await executionBlock(self)
        } catch {
            success = false
        }

        withStateLock {
            attemptInFlight = false
        }
    }

    /// Suspends until `finish(success:)` or `cancel()` is called.
    /// The lock ordering with `finish(success:)` guarantees no wakeup is lost.
    private func waitForManualFinish() async {
        await withCheckedContinuation { continuation in
            let parked: Bool = withStateLock {
                guard !hasFinished, !isCancelled, lastExecutedAttempt == _currentAttempt else {
                    return false
                }

                finishContinuation = continuation
                return true
            }

            if !parked {
                continuation.resume()
            }
        }
    }

    /// Notify the completion of asynchronous task and hence the completion of the `Operation`.
    /// Must be called when the `Operation` is finished.
    /// Once the `Operation` is finished, any subsequent call does nothing.
    ///
    /// - Parameter success: Set it to `false` if the `Operation` has failed, otherwise `true`.
    ///                      Default is `true`.
    open func finish(success: Bool = true) {
        stateLock.lock()
        guard !hasFinished else {
            stateLock.unlock()
            return
        }

        _success = success

        let continuation = finishContinuation
        finishContinuation = nil

        if success || _currentAttempt >= maximumRetries || isCancelled {
            hasFinished = true
            shouldRetry = false
            stateLock.unlock()

            /// State change notifications are sent outside the lock,
            /// the queue reacts to them synchronously.
            _executing = false
            _finished = true
        } else {
            _currentAttempt += 1
            shouldRetry = true
            stateLock.unlock()
        }

        /// Wake up the execution task, if it is suspended waiting for a manual finish.
        continuation?.resume()
    }

    /// Pause the current `Operation`, if it's supported.
    /// It can be overridden to add custom behavior.
    open func pause() {
        onPause?(self)
    }

    /// Resume the current `Operation`, if it's supported.
    /// It can be overridden to add custom behavior.
    open func resume() {
        onResume?(self)
    }

    /// Cancel the current `Operation`, if it's supported.
    /// The `Task` running the execution block is canceled too,
    /// so the block can react with the standard cooperative cancellation.
    override open func cancel() {
        super.cancel()
        onCancel?(self)

        stateLock.lock()
        let task = executionTask
        let continuation = finishContinuation
        finishContinuation = nil
        /// A started `Operation` that is idle between attempts, waiting for
        /// a manual `finish(success:)` or a manual `retry()`, would never
        /// finish on its own after being canceled, so it is finished here.
        /// An `Operation` in the middle of an attempt finishes on its own.
        let shouldFinish = hasStarted && !hasFinished && !attemptInFlight && executionBlock != nil
        stateLock.unlock()

        /// Propagate the cooperative cancellation to the execution block.
        task?.cancel()
        continuation?.resume()

        if shouldFinish {
            finish(success: success)
        }
    }
}

/// `AsyncConcurrentOperation` extension with queue handling.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AsyncConcurrentOperation {
    /// Adds the `Operation` to `shared` Queuer.
    public func addToSharedQueuer() {
        Queuer.shared.addOperation(self)
    }

    /// Adds the `Operation` to the custom queue.
    ///
    /// - Parameter queue: Custom queue where the `Operation` will be added.
    public func addToQueue(_ queue: Queuer) {
        queue.addOperation(self)
    }
}
