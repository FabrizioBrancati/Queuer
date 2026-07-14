//
//  AsyncConcurrentOperationTests.swift
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

private struct TestError: Error {}

@Suite("AsyncConcurrentOperation")
struct AsyncConcurrentOperationTests {
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Chained async operations retry and run in order")
    func chainedAsyncRetry() async {
        let queue = Queuer(name: "AsyncConcurrentOperationChainedRetry")
        let order = Protected<[Int]>([])
        let completed = Protected(false)

        let concurrentOperation1 = AsyncConcurrentOperation { operation in
            order.mutate { $0.append(0) }
            operation.success = false
        }
        let concurrentOperation2 = AsyncConcurrentOperation { operation in
            order.mutate { $0.append(1) }
            operation.success = false
        }
        queue.addChainedAsyncOperations([concurrentOperation1, concurrentOperation2]) {
            order.mutate { $0.append(2) }
            completed.mutate { $0 = true }
        }

        #expect(await waitUntil { completed.value })
        #expect(order.value == [0, 0, 0, 1, 1, 1, 2])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Thrown errors mark attempts as failed and are retried")
    func throwingBlockRetriesAndFails() async {
        let queue = Queuer(name: "AsyncConcurrentOperationThrowingBlock")
        let attempts = Protected(0)

        let concurrentOperation = AsyncConcurrentOperation { _ in
            attempts.mutate { $0 += 1 }
            throw TestError()
        }
        concurrentOperation.addToQueue(queue)

        #expect(await waitUntil { concurrentOperation.isFinished })
        #expect(attempts.value == 3)
        #expect(concurrentOperation.success == false)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Canceling the operation cancels its task")
    func cancellationStopsTheOperation() async {
        let queue = Queuer(name: "AsyncConcurrentOperationCancellation")
        let started = Protected(false)

        let concurrentOperation = AsyncConcurrentOperation { _ in
            started.mutate { $0 = true }
            /// The cooperative cancellation interrupts this sleep right away.
            try await Task.sleep(nanoseconds: 8_000_000_000)
        }
        concurrentOperation.addToQueue(queue)

        #expect(await waitUntil { started.value })
        concurrentOperation.cancel()

        #expect(await waitUntil { concurrentOperation.isFinished })
        #expect(concurrentOperation.isCancelled)
        #expect(concurrentOperation.success == false)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Async manual finish completes the operation")
    func manualFinishCompletesTheOperation() async {
        let queue = Queuer(name: "AsyncConcurrentOperationManualFinish")
        let executed = Protected(false)

        let concurrentOperation = AsyncConcurrentOperation { _ in
            executed.mutate { $0 = true }
        }
        concurrentOperation.manualFinish = true
        concurrentOperation.addToQueue(queue)

        #expect(await waitUntil { executed.value })
        #expect(concurrentOperation.isFinished == false)

        concurrentOperation.finish()

        #expect(await waitUntil { concurrentOperation.isFinished })
        #expect(concurrentOperation.success)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Async retry delay throttles automatic retries")
    func retryDelayThrottlesAutomaticRetries() async {
        let queue = Queuer(name: "AsyncConcurrentOperationRetryDelay")
        let start = Date()

        let concurrentOperation = AsyncConcurrentOperation { operation in
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
    @Test("Async completion waits for every operation in the queue")
    func asyncCompletionWaitsForAllOperations() async {
        let queue = Queuer(name: "AsyncConcurrentOperationAsyncCompletion")
        let order = Protected<[String]>([])
        let completed = Protected(false)

        let concurrentOperation = AsyncConcurrentOperation { _ in
            order.mutate { $0.append("operation") }
        }
        concurrentOperation.addToQueue(queue)

        queue.addAsyncCompletionHandler {
            order.mutate { $0.append("done") }
            completed.mutate { $0 = true }
        }

        #expect(await waitUntil { completed.value })
        #expect(order.value.last == "done")
    }
}
