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

import Queuer
import XCTest

private struct TestError: Error {}

final class AsyncConcurrentOperationTests: XCTestCase {
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func testChainedAsyncRetry() {
        let queue = Queuer(name: "AsyncConcurrentOperationChainedRetry")
        let testExpectation = expectation(description: "Chained Async Retry")
        let order = Protected<[Int]>([])

        let concurrentOperation1 = AsyncConcurrentOperation { operation in
            order.append(0)
            operation.success = false
        }
        let concurrentOperation2 = AsyncConcurrentOperation { operation in
            order.append(1)
            operation.success = false
        }
        queue.addChainedAsyncOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0, 0, 0, 1, 1, 1, 2])
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func testThrowingBlockRetriesAndFails() {
        let queue = Queuer(name: "AsyncConcurrentOperationThrowingBlock")
        let testExpectation = expectation(description: "Throwing Block Retries And Fails")
        let attempts = Protected(0)

        /// A thrown error marks the attempt as failed, enabling the retry feature.
        let concurrentOperation = AsyncConcurrentOperation { _ in
            attempts.mutate { $0 += 1 }
            throw TestError()
        }
        /// `completionBlock` is only called once the operation is finished,
        /// so every retry is guaranteed to be over by then.
        concurrentOperation.completionBlock = {
            testExpectation.fulfill()
        }
        concurrentOperation.addToQueue(queue)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(attempts.value, 3)
            XCTAssertFalse(concurrentOperation.success)
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func testCancellationStopsTheOperation() {
        let queue = Queuer(name: "AsyncConcurrentOperationCancellation")
        let testExpectation = expectation(description: "Cancellation Stops The Operation")
        let started = Protected(false)

        let concurrentOperation = AsyncConcurrentOperation { _ in
            started.mutate { $0 = true }
            /// The cooperative cancellation interrupts this sleep right away.
            try await Task.sleep(nanoseconds: 8_000_000_000)
        }
        concurrentOperation.completionBlock = {
            testExpectation.fulfill()
        }
        concurrentOperation.addToQueue(queue)

        onBackgroundThread {
            waitUntil(timeout: 8) { started.value }
            concurrentOperation.cancel()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertTrue(concurrentOperation.isCancelled)
            XCTAssertTrue(concurrentOperation.isFinished)
            XCTAssertFalse(concurrentOperation.success)
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func testManualFinishCompletesTheOperation() {
        let queue = Queuer(name: "AsyncConcurrentOperationManualFinish")
        let testExpectation = expectation(description: "Manual Finish Completes The Operation")
        let executed = Protected(false)
        let finishedBeforeManualFinish = Protected(true)

        let concurrentOperation = AsyncConcurrentOperation { _ in
            executed.mutate { $0 = true }
        }
        concurrentOperation.manualFinish = true
        concurrentOperation.completionBlock = {
            testExpectation.fulfill()
        }
        concurrentOperation.addToQueue(queue)

        onBackgroundThread {
            waitUntil(timeout: 8) { executed.value }
            /// The operation must not be finished until `finish(success:)` is called.
            finishedBeforeManualFinish.mutate { $0 = concurrentOperation.isFinished }
            concurrentOperation.finish()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertFalse(finishedBeforeManualFinish.value)
            XCTAssertTrue(concurrentOperation.isFinished)
            XCTAssertTrue(concurrentOperation.success)
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func testRetryDelayThrottlesAutomaticRetries() {
        let queue = Queuer(name: "AsyncConcurrentOperationRetryDelay")
        let testExpectation = expectation(description: "Retry Delay Throttles Automatic Retries")
        let start = Date()

        let concurrentOperation = AsyncConcurrentOperation { operation in
            operation.success = false
        }
        concurrentOperation.retryDelay = 0.2
        concurrentOperation.completionBlock = {
            testExpectation.fulfill()
        }
        concurrentOperation.addToQueue(queue)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(concurrentOperation.currentAttempt, 3)
            /// Three attempts with two delays in between must take at least 0.4 seconds.
            /// A lenient lower bound avoids failures from clock differences.
            XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 0.3)
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func testAsyncCompletionWaitsForAllOperations() {
        let queue = Queuer(name: "AsyncConcurrentOperationAsyncCompletion")
        let testExpectation = expectation(description: "Async Completion Waits For All Operations")
        let order = Protected<[String]>([])

        let concurrentOperation = AsyncConcurrentOperation { _ in
            order.append("operation")
        }
        concurrentOperation.addToQueue(queue)

        queue.addAsyncCompletionHandler {
            order.append("done")
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value.last, "done")
        }
    }
}
