//
//  ConcurrentOperationTests.swift
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
import Queuer
import Testing

@Suite("ConcurrentOperation")
struct ConcurrentOperationTests {
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Init with execution block executes it")
    func initWithExecutionBlock() async {
        let queue = Queuer(name: "ConcurrentOperationTestInitWithExecutionBlock")
        let executed = Protected(false)

        let concurrentOperation = ConcurrentOperation { _ in
            executed.mutate { $0 = true }
        }
        concurrentOperation.addToQueue(queue)

        #expect(await waitUntil { executed.value })
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Add to queue")
    func addToQueue() async {
        let queue = Queuer(name: "ConcurrentOperationTestAddToQueuer")
        let releaseOperation = DispatchSemaphore(value: 0)

        /// Hold the operation in the queue until the asserts have been made.
        let concurrentOperation = ConcurrentOperation { _ in
            _ = releaseOperation.wait(timeout: .now() + .seconds(8))
        }
        concurrentOperation.addToQueue(queue)

        #expect(queue.operationCount == 1)
        #expect(queue.operations == [concurrentOperation])

        releaseOperation.signal()
        #expect(await waitUntil { queue.operationCount == 0 })
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Failed operations are retried three times")
    func simpleRetry() async {
        let queue = Queuer(name: "ConcurrentOperationTestSimpleRetry")
        let finished = Protected(false)

        let concurrentOperation = ConcurrentOperation { operation in
            operation.success = false
        }
        /// `completionBlock` is only called once the operation is finished,
        /// so every retry is guaranteed to be over by then.
        concurrentOperation.completionBlock = {
            finished.mutate { $0 = true }
        }
        concurrentOperation.addToQueue(queue)

        #expect(await waitUntil { finished.value })
        #expect(concurrentOperation.success == false)
        #expect(concurrentOperation.currentAttempt == 3)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Chained operations retry and run in order")
    func chainedRetry() async {
        let queue = Queuer(name: "ConcurrentOperationTestChainedRetry")
        let order = Protected<[Int]>([])
        let completed = Protected(false)

        let concurrentOperation1 = ConcurrentOperation { operation in
            order.append(0)
            operation.success = false
        }
        let concurrentOperation2 = ConcurrentOperation { operation in
            order.append(1)
            operation.success = false
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
            completed.mutate { $0 = true }
        }

        #expect(await waitUntil { completed.value })
        #expect(order.value == [0, 0, 0, 1, 1, 1, 2])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Chained operations with manual finish from a task retry in order")
    func asyncChainedRetry() async {
        let queue = Queuer(name: "ConcurrentOperationTestAsyncChainedRetry")
        let order = Protected<[Int]>([])
        let completed = Protected(false)

        let concurrentOperation1 = ConcurrentOperation { operation in
            Task {
                order.append(0)
                operation.finish(success: false)
            }
        }
        concurrentOperation1.manualFinish = true
        let concurrentOperation2 = ConcurrentOperation { operation in
            Task {
                order.append(1)
                operation.finish(success: false)
            }
        }
        concurrentOperation2.manualFinish = true
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
            completed.mutate { $0 = true }
        }

        /// Every attempt hops through an unstructured `Task`:
        /// give slow emulators with few cores some extra headroom.
        #expect(await waitUntil(timeout: 20) { completed.value })
        #expect(order.value == [0, 0, 0, 1, 1, 1, 2])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Self canceled chained operation does not retry")
    func canceledChainedRetry() async {
        let queue = Queuer(name: "ConcurrentOperationTestCanceledChainedRetry")
        let order = Protected<[Int]>([])
        let completed = Protected(false)

        let concurrentOperation1 = ConcurrentOperation { operation in
            order.append(0)
            operation.success = false
        }
        let concurrentOperation2 = ConcurrentOperation { operation in
            operation.cancel()
            guard !operation.isCancelled else {
                return
            }
            order.append(1)
            operation.success = false
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
            completed.mutate { $0 = true }
        }

        #expect(await waitUntil { completed.value })
        #expect(order.value == [0, 0, 0, 2])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Chained manual retries run in order")
    func chainedManualRetry() async {
        let queue = Queuer(name: "ConcurrentOperationTestChainedManualRetry")
        let order = Protected<[Int]>([])
        let completed = Protected(false)

        let concurrentOperation1 = ConcurrentOperation(name: "concurrentOperation1") { operation in
            operation.success = false
            order.append(0)
        }
        concurrentOperation1.manualRetry = true

        let concurrentOperation2 = ConcurrentOperation(name: "concurrentOperation2") { operation in
            operation.success = false
            order.append(1)
        }

        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
            completed.mutate { $0 = true }
        }

        /// Trigger a retry as soon as the previous attempt has been executed,
        /// instead of relying on wall clock delays.
        onBackgroundThread {
            guard waitUntil(timeout: 8, { order.count >= 1 && concurrentOperation1.currentAttempt == 2 }) else { return }
            concurrentOperation1.retry()
            guard waitUntil(timeout: 8, { order.count >= 2 && concurrentOperation1.currentAttempt == 3 }) else { return }
            concurrentOperation1.retry()
        }

        #expect(await waitUntil { completed.value })
        #expect(order.value == [0, 0, 0, 1, 1, 1, 2])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Without manual retries the chain stalls")
    func chainedWrongManualRetry() async {
        let queue = Queuer(name: "ConcurrentOperationTestChainedWrongManualRetry")
        let order = Protected<[Int]>([])

        let concurrentOperation1 = ConcurrentOperation { operation in
            order.append(0)
            operation.success = false
        }
        concurrentOperation1.manualRetry = true

        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
        }

        /// `retry()` is never called, so the chain must stall after the first attempt.
        /// Give it a bounded amount of time to (wrongly) make progress before asserting.
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        #expect(order.value == [0])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Concurrent operations can be ordered with semaphores")
    func concurrentOperation() async {
        let queue = Queuer(name: "ConcurrentOperation")
        let testString = Protected("")
        let completed = Protected(false)
        let firstOperationDone = DispatchSemaphore(value: 0)

        let concurrentOperation1 = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested1" }
            firstOperationDone.signal()
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            /// Deterministically run after `concurrentOperation1`, without sleeping.
            _ = firstOperationDone.wait(timeout: .now() + .seconds(8))
            testString.mutate { $0 = "Tested2" }
            completed.mutate { $0 = true }
        }
        concurrentOperation1.addToQueue(queue)
        concurrentOperation2.addToQueue(queue)

        #expect(await waitUntil { completed.value })
        #expect(testString.value == "Tested2")
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Failed operation retries after the other operations")
    func concurrentOperationRetry() async {
        let queue = Queuer(name: "ConcurrentOperationRetry")
        let order = Protected<[Int]>([])
        let secondOperationDone = DispatchSemaphore(value: 0)

        /// The signaling operation is enqueued first so the test also works
        /// if the queue is effectively serial on a starved runner.
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
            secondOperationDone.signal()
        }
        concurrentOperation2.addToQueue(queue)

        let concurrentOperation1 = ConcurrentOperation { operation in
            /// Wait for the other operation only on the first attempt,
            /// the retries happen after it has already finished.
            if operation.currentAttempt == 1 {
                _ = secondOperationDone.wait(timeout: .now() + .seconds(8))
            }

            order.append(0)
            operation.success = false
        }
        concurrentOperation1.addToQueue(queue)

        #expect(await waitUntil { concurrentOperation1.isFinished })
        #expect(order.value == [1, 0, 0, 0])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Canceling a queue stops pending operations")
    func cancel() async {
        let queue = Queuer(name: "TestCancel", maxConcurrentOperationCount: 1)
        let testString = Protected("")
        let firstOperationStarted = DispatchSemaphore(value: 0)
        let queueCanceled = DispatchSemaphore(value: 0)

        let concurrentOperation1 = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested1" }
            firstOperationStarted.signal()
            /// Keep the operation running until the queue has been canceled.
            _ = queueCanceled.wait(timeout: .now() + .seconds(8))
        }
        /// A canceled `Operation` must never execute its block,
        /// so `testString` has to remain "Tested1".
        let concurrentOperation2 = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested2" }
        }
        concurrentOperation1.addToQueue(queue)
        concurrentOperation2.addToQueue(queue)

        onBackgroundThread {
            _ = firstOperationStarted.wait(timeout: .now() + .seconds(8))
            queue.cancel()
            queueCanceled.signal()
        }

        #expect(await waitUntil { concurrentOperation1.isFinished && concurrentOperation2.isCancelled })
        #expect(testString.value == "Tested1")
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Manual finish completes the operation")
    func manualFinish() async {
        let queue = Queuer(name: "ManualFinish")
        let operationStarted = DispatchSemaphore(value: 0)
        let finishedBeforeManualFinish = Protected(true)

        let concurrentOperation = ConcurrentOperation { _ in
            operationStarted.signal()
        }
        concurrentOperation.manualFinish = true

        concurrentOperation.addToQueue(queue)

        onBackgroundThread {
            _ = operationStarted.wait(timeout: .now() + .seconds(8))
            /// The operation must not be finished until `finish(success:)` is called.
            finishedBeforeManualFinish.mutate { $0 = concurrentOperation.isFinished }
            concurrentOperation.finish()
        }

        #expect(await waitUntil { concurrentOperation.isFinished })
        #expect(finishedBeforeManualFinish.value == false)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Chained manual retries with manual finish run every attempt")
    func chainedManualRetryAndManualFinish() async {
        let queue = Queuer(name: "ConcurrentOperationTestChainedManualRetryAndManualFinish")
        let order = Protected<[Int]>([])
        let finishedBeforeManualFinish = Protected(true)

        let concurrentOperation = ConcurrentOperation(name: "concurrentOperation1") { operation in
            operation.success = false
            order.append(0)
        }
        concurrentOperation.manualRetry = true
        concurrentOperation.manualFinish = true

        concurrentOperation.addToQueue(queue)

        onBackgroundThread {
            guard waitUntil(timeout: 8, { order.count >= 1 }) else { return }
            concurrentOperation.retry()
            guard waitUntil(timeout: 8, { order.count >= 2 }) else { return }
            concurrentOperation.retry()
            guard waitUntil(timeout: 8, { order.count >= 3 }) else { return }
            /// The operation must not be finished until `finish(success:)` is called.
            finishedBeforeManualFinish.mutate { $0 = concurrentOperation.isFinished }
            concurrentOperation.finish()
        }

        #expect(await waitUntil { concurrentOperation.isFinished })
        #expect(order.value == [0, 0, 0])
        #expect(finishedBeforeManualFinish.value == false)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Retry before start is ignored")
    func retryBeforeStartIsIgnored() async {
        let queue = Queuer(name: "ConcurrentOperationTestRetryBeforeStart")
        let order = Protected<[Int]>([])

        let concurrentOperation = ConcurrentOperation { _ in
            order.append(0)
        }
        concurrentOperation.manualRetry = true

        /// A `retry()` before the queue starts the `Operation` must do nothing,
        /// otherwise the `Operation` would execute on the caller's thread
        /// and could not be added to a queue anymore.
        concurrentOperation.retry()
        #expect(order.value == [])
        #expect(concurrentOperation.isFinished == false)

        concurrentOperation.addToQueue(queue)

        #expect(await waitUntil { concurrentOperation.isFinished })
        #expect(order.value == [0])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Operations without an execution block finish on their own")
    func operationWithoutExecutionBlockFinishes() async {
        let queue = Queuer(name: "ConcurrentOperationTestWithoutExecutionBlock")

        let concurrentOperation = ConcurrentOperation()
        concurrentOperation.addToQueue(queue)

        /// An `Operation` without an execution block must finish on its own,
        /// otherwise it would occupy the queue forever.
        #expect(await waitUntil { queue.operationCount == 0 })
        #expect(concurrentOperation.isFinished)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Retry delay throttles automatic retries")
    func retryDelayThrottlesAutomaticRetries() async {
        let queue = Queuer(name: "ConcurrentOperationTestRetryDelay")
        let start = Date()

        let concurrentOperation = ConcurrentOperation { operation in
            operation.success = false
        }
        concurrentOperation.retryDelay = 0.2
        concurrentOperation.addToQueue(queue)

        #expect(await waitUntil { concurrentOperation.isFinished })
        #expect(concurrentOperation.currentAttempt == 3)
        /// Three attempts with two delays in between must take at least 0.4 seconds.
        /// A lenient lower bound avoids failures from clock differences.
        #expect(Date().timeIntervalSince(start) >= 0.3)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Canceling wakes an operation waiting for a manual finish")
    func cancelWhileWaitingForManualFinish() async {
        let queue = Queuer(name: "ConcurrentOperationTestCancelWhileWaitingForManualFinish")
        let operationStarted = DispatchSemaphore(value: 0)

        let concurrentOperation = ConcurrentOperation { _ in
            operationStarted.signal()
        }
        concurrentOperation.manualFinish = true
        concurrentOperation.addToQueue(queue)

        onBackgroundThread {
            _ = operationStarted.wait(timeout: .now() + .seconds(8))
            /// Canceling an `Operation` that is waiting for a manual finish
            /// must wake it up and finish it.
            concurrentOperation.cancel()
        }

        #expect(await waitUntil { concurrentOperation.isFinished })
        #expect(concurrentOperation.isCancelled)
    }
}
