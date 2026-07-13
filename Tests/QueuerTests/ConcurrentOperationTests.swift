//
//  ConcurrentOperationTests.swift
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

import Queuer
import XCTest

final class ConcurrentOperationTests: XCTestCase {
    func testInitWithExecutionBlock() {
        let queue = Queuer(name: "ConcurrentOperationTestInitWithExecutionBlock")

        let testExpectation = expectation(description: "Init With Execution Block")

        let concurrentOperation = ConcurrentOperation { _ in
            testExpectation.fulfill()
        }
        concurrentOperation.addToQueue(queue)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testAddToSharedQueuer() {
        let releaseOperation = DispatchSemaphore(value: 0)

        /// Hold the operation in the queue until the asserts have been made.
        let concurrentOperation = ConcurrentOperation { _ in
            _ = releaseOperation.wait(timeout: .now() + .seconds(8))
        }
        concurrentOperation.addToSharedQueuer()

        XCTAssertGreaterThanOrEqual(Queuer.shared.operationCount, 1)
        XCTAssertTrue(Queuer.shared.operations.contains(concurrentOperation))

        releaseOperation.signal()

        /// Leave the shared queue clean for the other tests.
        Queuer.shared.waitUntilAllOperationsAreFinished()
    }

    func testAddToQueue() {
        let queue = Queuer(name: "ConcurrentOperationTestAddToQueuer")
        let releaseOperation = DispatchSemaphore(value: 0)

        /// Hold the operation in the queue until the asserts have been made.
        let concurrentOperation = ConcurrentOperation { _ in
            _ = releaseOperation.wait(timeout: .now() + .seconds(8))
        }
        concurrentOperation.addToQueue(queue)

        XCTAssertEqual(queue.operationCount, 1)
        XCTAssertEqual(queue.operations, [concurrentOperation])

        releaseOperation.signal()
        queue.waitUntilAllOperationsAreFinished()
    }

    func testSimpleRetry() {
        let queue = Queuer(name: "ConcurrentOperationTestSimpleRetry")

        let testExpectation = expectation(description: "Simple Retry")

        let concurrentOperation = ConcurrentOperation { operation in
            operation.success = false
        }
        /// `completionBlock` is only called once the operation is finished,
        /// so every retry is guaranteed to be over by then.
        concurrentOperation.completionBlock = {
            testExpectation.fulfill()
        }
        concurrentOperation.addToQueue(queue)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertFalse(concurrentOperation.success)
            XCTAssertEqual(concurrentOperation.currentAttempt, 3)
        }
    }

    func testChainedRetry() {
        let queue = Queuer(name: "ConcurrentOperationTestChainedRetry")
        let testExpectation = expectation(description: "Chained Retry")
        let order = Protected<[Int]>([])

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
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0, 0, 0, 1, 1, 1, 2])
        }
    }

    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    func testAsyncChainedRetry() async {
        let queue = Queuer(name: "ConcurrentOperationTestChainedRetry")
        let testExpectation = expectation(description: "Chained Retry")
        let order = OrderHelper()

        let concurrentOperation1 = ConcurrentOperation { operation in
            Task {
                await order.append(0)
                operation.finish(success: false)
            }
        }
        concurrentOperation1.manualFinish = true
        let concurrentOperation2 = ConcurrentOperation { operation in
            Task {
                await order.append(1)
                operation.finish(success: false)
            }
        }
        concurrentOperation2.manualFinish = true
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            Task {
                await order.append(2)
                testExpectation.fulfill()
            }
        }

        await fulfillment(of: [testExpectation], timeout: 10)
        let finalOrder = await order.order
        XCTAssertEqual(finalOrder, [0, 0, 0, 1, 1, 1, 2])
    }

    func testCanceledChainedRetry() {
        let queue = Queuer(name: "ConcurrentOperationTestCanceledChainedRetry")
        let testExpectation = expectation(description: "Canceled Chained Retry")
        let order = Protected<[Int]>([])

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
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0, 0, 0, 2])
        }
    }

    func testChainedManualRetry() {
        let queue = Queuer(name: "ConcurrentOperationTestChainedManualRetry")
        let testExpectation = expectation(description: "Chained Manual Retry")
        let order = Protected<[Int]>([])

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
            testExpectation.fulfill()
        }

        /// Trigger a retry as soon as the previous attempt has been executed,
        /// instead of relying on wall clock delays.
        onBackgroundThread {
            waitUntil(timeout: 8) { order.count >= 1 && concurrentOperation1.currentAttempt == 2 }
            concurrentOperation1.retry()
            waitUntil(timeout: 8) { order.count >= 2 && concurrentOperation1.currentAttempt == 3 }
            concurrentOperation1.retry()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0, 0, 0, 1, 1, 1, 2])
        }
    }

    func testChainedWrongManualRetry() {
        let queue = Queuer(name: "ConcurrentOperationTestChainedWrongManualRetry")
        let testExpectation = expectation(description: "Chained Wrong Manual Retry")
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
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0])
        }
    }

    func testConcurrentOperation() {
        let queue = Queuer(name: "ConcurrentOperation")
        let testExpectation = expectation(description: "Concurrent Operation")
        let testString = Protected("")
        let firstOperationDone = DispatchSemaphore(value: 0)

        let concurrentOperation1 = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested1" }
            firstOperationDone.signal()
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            /// Deterministically run after `concurrentOperation1`, without sleeping.
            _ = firstOperationDone.wait(timeout: .now() + .seconds(8))
            testString.mutate { $0 = "Tested2" }

            testExpectation.fulfill()
        }
        concurrentOperation1.addToQueue(queue)
        concurrentOperation2.addToQueue(queue)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(testString.value, "Tested2")
        }
    }

    func testConcurrentOperationOnSharedQueuer() {
        let testExpectation = expectation(description: "Concurrent Operation")
        let testString = Protected("")
        let secondOperationDone = DispatchSemaphore(value: 0)

        let concurrentOperation1 = ConcurrentOperation { _ in
            _ = secondOperationDone.wait(timeout: .now() + .seconds(8))
            testString.mutate { $0 = "Tested1" }

            testExpectation.fulfill()
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested2" }
            secondOperationDone.signal()
        }
        Queuer.shared.maxConcurrentOperationCount = 2
        concurrentOperation2.addToSharedQueuer()
        concurrentOperation1.addToSharedQueuer()

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(testString.value, "Tested1")
        }
    }

    func testConcurrentOperationRetry() {
        let queue = Queuer(name: "ConcurrentOperationRetry")
        let testExpectation = expectation(description: "Concurrent Operation Retry")
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

            if operation.currentAttempt == 3 {
                testExpectation.fulfill()
            }
        }
        concurrentOperation1.addToQueue(queue)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [1, 0, 0, 0])
        }
    }

    func testCancel() {
        let queue = Queuer(name: "TestCancel", maxConcurrentOperationCount: 1)
        let testExpectation = expectation(description: "Cancel")
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
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(testString.value, "Tested1")
            XCTAssertTrue(concurrentOperation2.isCancelled)
        }
    }

    func testManualFinish() {
        let queue = Queuer(name: "ManualFinish")
        let testExpectation = expectation(description: "Manual Finish")
        let operationStarted = DispatchSemaphore(value: 0)

        let concurrentOperation = ConcurrentOperation { _ in
            operationStarted.signal()
        }
        concurrentOperation.manualFinish = true

        concurrentOperation.addToQueue(queue)

        onBackgroundThread {
            _ = operationStarted.wait(timeout: .now() + .seconds(8))
            XCTAssertFalse(concurrentOperation.isFinished)
            concurrentOperation.finish()
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertTrue(concurrentOperation.isFinished)
        }
    }

    func testChainedManualRetryAndManualFinish() {
        let queue = Queuer(name: "ConcurrentOperationTestChainedManualRetryAndManualFinish")
        let testExpectation = expectation(description: "Chained Manual Retry And Manual Finish")
        let order = Protected<[Int]>([])

        let concurrentOperation = ConcurrentOperation(name: "concurrentOperation1") { operation in
            operation.success = false
            order.append(0)
        }
        concurrentOperation.manualRetry = true
        concurrentOperation.manualFinish = true

        concurrentOperation.addToQueue(queue)

        onBackgroundThread {
            waitUntil(timeout: 8) { order.count >= 1 }
            concurrentOperation.retry()
            waitUntil(timeout: 8) { order.count >= 2 }
            concurrentOperation.retry()
            waitUntil(timeout: 8) { order.count >= 3 }
            XCTAssertFalse(concurrentOperation.isFinished)
            concurrentOperation.finish()
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0, 0, 0])
            XCTAssertTrue(concurrentOperation.isFinished)
        }
    }
}
