//
//  GroupOperationTests.swift
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

import Dispatch
import Queuer
import XCTest

final class GroupOperationTests: XCTestCase {
    func testGroupOperations() {
        let order = Protected<[String]>([])
        let testExpectation = expectation(description: "GroupOperations")
        let queue = Queuer(name: "Group Operations")
        let operation2Done = DispatchSemaphore(value: 0)
        let group1Done = DispatchSemaphore(value: 0)
        let operation4Done = DispatchSemaphore(value: 0)
        let group2Done = DispatchSemaphore(value: 0)

        /// The signaling operation is enqueued first so the test also works
        /// if the inner queue is effectively serial on a starved runner.
        let groupOperation1 = GroupOperation(
            [
                ConcurrentOperation { _ in
                    order.append("2")
                    operation2Done.signal()
                },
                ConcurrentOperation { _ in
                    /// Deterministically run after the "2" operation, without sleeping.
                    _ = operation2Done.wait(timeout: .now() + .seconds(8))
                    order.append("1")
                }
            ]
        ) {
            order.append("3")
            group1Done.signal()
        }

        let groupOperation2 = GroupOperation(
            [
                ConcurrentOperation { _ in
                    /// The completion block of the previous group runs asynchronously,
                    /// wait for it to keep the recorded order deterministic.
                    _ = group1Done.wait(timeout: .now() + .seconds(8))
                    order.append("4")
                    operation4Done.signal()
                },
                ConcurrentOperation { _ in
                    _ = operation4Done.wait(timeout: .now() + .seconds(8))
                    order.append("5")
                }
            ]
        ) {
            order.append("6")
            group2Done.signal()
        }

        let groupOperation3 = ConcurrentOperation { _ in
            _ = group2Done.wait(timeout: .now() + .seconds(8))
            order.append("7")
        }

        queue.addChainedOperations([groupOperation1, groupOperation2, groupOperation3]) {
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertTrue(groupOperation1.allOperationsSucceeded)
            XCTAssertNil(error)
            XCTAssertEqual(order.value, ["2", "1", "3", "4", "5", "6", "7"])
        }
    }

    func testGroupOperationsWithInnerChainedRetry() {
        let order = Protected<[String]>([])
        let testExpectation = expectation(description: "GroupOperationsWithInnerChainedRetry")
        let queue = Queuer(name: "Group Operations Chained Retry")
        let operation1Done = DispatchSemaphore(value: 0)

        let groupOperation1 = GroupOperation(
            [
                ConcurrentOperation { _ in
                    order.append("1")
                    operation1Done.signal()
                },
                ConcurrentOperation { operation in
                    /// Wait for the other operation only on the first attempt,
                    /// the retries happen after it has already finished.
                    if operation.currentAttempt == 1 {
                        _ = operation1Done.wait(timeout: .now() + .seconds(8))
                    }
                    order.append("2")
                    operation.success = false
                }
            ]
        )

        let groupOperation2 = ConcurrentOperation { _ in
            order.append("3")
        }

        queue.addChainedOperations([groupOperation1, groupOperation2]) {
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, ["1", "2", "2", "2", "3"])
        }
    }

    func testGroupOperationsWithCancelledInnerChainedRetry() {
        let queue = Queuer(name: "GroupOperationsWithCancelledInnerChainedRetry")
        let testExpectation = expectation(description: "Group Operations Cancelled Inner Chained Retry")
        let order = Protected<[String]>([])

        let groupOperation1 = GroupOperation(
            [
                ConcurrentOperation { operation in
                    order.append("1")
                    operation.success = false
                },
                ConcurrentOperation { operation in
                    operation.cancel()
                    guard !operation.isCancelled else {
                        return
                    }
                    order.append("2")
                    operation.success = false
                }
            ]
        )

        let groupOperation2 = ConcurrentOperation { _ in
            order.append("3")
        }

        queue.addChainedOperations([groupOperation1, groupOperation2]) {
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, ["1", "1", "1", "3"])
        }
    }

    func testGroupOperationsWithInnerChainedManualRetry() {
        let queue = Queuer(name: "GroupOperationsWithInnerChainedManualRetry")
        let testExpectation = expectation(description: "Group Operations Inner Chained Manual Retry")
        let order = Protected<[String]>([])
        let operation1Done = DispatchSemaphore(value: 0)

        let concurrentOperation1 = ConcurrentOperation { operation in
            order.append("1")

            if operation.currentAttempt == 1 {
                operation1Done.signal()
            }

            operation.success = false
        }
        concurrentOperation1.manualRetry = true

        let concurrentOperation2 = ConcurrentOperation { operation in
            if operation.currentAttempt == 1 {
                _ = operation1Done.wait(timeout: .now() + .seconds(8))
            }

            order.append("2")
            operation.success = false
        }
        concurrentOperation2.manualRetry = true

        let groupOperation1 = GroupOperation([concurrentOperation1, concurrentOperation2])

        let groupOperation2 = ConcurrentOperation { _ in
            order.append("3")
        }

        queue.addChainedOperations([groupOperation1, groupOperation2]) {
            testExpectation.fulfill()
        }

        /// Trigger every retry as soon as the previous attempt has been recorded,
        /// instead of relying on wall clock delays.
        onBackgroundThread {
            waitUntil(timeout: 8) { order.count >= 2 && concurrentOperation1.currentAttempt == 2 }
            concurrentOperation1.retry()
            waitUntil(timeout: 8) { order.count >= 3 && concurrentOperation2.currentAttempt == 2 }
            concurrentOperation2.retry()
            waitUntil(timeout: 8) { order.count >= 4 && concurrentOperation2.currentAttempt == 3 }
            concurrentOperation2.retry()
            waitUntil(timeout: 8) { order.count >= 5 && concurrentOperation1.currentAttempt == 3 }
            concurrentOperation1.retry()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, ["1", "2", "1", "2", "2", "1", "3"])
        }
    }

    func testCancelGroupOperationCancelsInnerOperations() {
        let queue = Queuer(name: "GroupOperationTestCancel")
        let testExpectation = expectation(description: "Cancel Group Operation Cancels Inner Operations")
        let order = Protected<[String]>([])
        let firstOperationStarted = DispatchSemaphore(value: 0)
        let releaseOperations = DispatchSemaphore(value: 0)

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append("1")
            firstOperationStarted.signal()
            _ = releaseOperations.wait(timeout: .now() + .seconds(8))
        }
        let concurrentOperation2 = ConcurrentOperation { operation in
            _ = releaseOperations.wait(timeout: .now() + .seconds(8))
            guard !operation.isCancelled else {
                return
            }
            order.append("2")
        }
        let groupOperation = GroupOperation([concurrentOperation1, concurrentOperation2])
        groupOperation.addToQueue(queue)

        onBackgroundThread {
            _ = firstOperationStarted.wait(timeout: .now() + .seconds(8))
            /// Canceling the group must cancel its inner operations too.
            groupOperation.cancel()
            releaseOperations.signal()
            releaseOperations.signal()
        }

        fulfill(testExpectation, when: { groupOperation.isFinished })

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, ["1"])
            XCTAssertTrue(groupOperation.isCancelled)
            XCTAssertTrue(concurrentOperation1.isCancelled)
            XCTAssertTrue(concurrentOperation2.isCancelled)
        }
    }
}
