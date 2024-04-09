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

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }

    func testIsAsynchronous() {
        let concurrentOperation = ConcurrentOperation()

        XCTAssertTrue(concurrentOperation.isAsynchronous)
    }

    func testAddToSharedQueuer() {
        let concurrentOperation = ConcurrentOperation()
        concurrentOperation.addToSharedQueuer()

        XCTAssertEqual(Queuer.shared.operationCount, 1)
        XCTAssertEqual(Queuer.shared.operations, [concurrentOperation])
    }

    func testAddToQueue() {
        let queue = Queuer(name: "ConcurrentOperationTestAddToQueuer")

        let concurrentOperation = ConcurrentOperation()
        concurrentOperation.addToQueue(queue)

        XCTAssertEqual(queue.operationCount, 1)
        XCTAssertEqual(queue.operations, [concurrentOperation])
    }

    func testSimpleRetry() {
        let queue = Queuer(name: "ConcurrentOperationTestSimpleRetry")

        let testExpectation = expectation(description: "Simple Retry")

        let concurrentOperation = ConcurrentOperation { operation in
            operation.success = false
        }
        queue.addCompletionHandler {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(1)) {
                testExpectation.fulfill()
            }
        }
        concurrentOperation.addToQueue(queue)

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertFalse(concurrentOperation.success)
            XCTAssertEqual(concurrentOperation.currentAttempt, 3)
        }
    }

    func testChainedRetry() {
        let queue = Queuer(name: "ConcurrentOperationTestChainedRetry")
        let testExpectation = expectation(description: "Chained Retry")
        var order: [Int] = []

        let concurrentOperation1 = ConcurrentOperation { operation in
            Thread.sleep(forTimeInterval: 1)
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

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, [0, 0, 0, 1, 1, 1, 2])
        }
    }

    func testCanceledChainedRetry() {
        let queue = Queuer(name: "ConcurrentOperationTestCanceledChainedRetry")
        let testExpectation = expectation(description: "Canceled Chained Retry")
        var order: [Int] = []

        let concurrentOperation1 = ConcurrentOperation { operation in
            Thread.sleep(forTimeInterval: 1)
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

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, [0, 0, 0, 2])
        }
    }

    func testChainedManualRetry() {
        let queue = Queuer(name: "ConcurrentOperationTestChainedManualRetry")
        let testExpectation = expectation(description: "Chained Manual Retry")
        var order: [Int] = []

        let concurrentOperation1 = ConcurrentOperation(name: "concurrentOperation1") { operation in
            operation.success = false
            order.append(0)
        }
        concurrentOperation1.manualRetry = true

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            concurrentOperation1.retry()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
            concurrentOperation1.retry()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(6)) {
            concurrentOperation1.retry()
        }

        let concurrentOperation2 = ConcurrentOperation(name: "concurrentOperation2") { operation in
            operation.success = false
            order.append(1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
                order.append(2)
                testExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, [0, 0, 0, 1, 1, 1, 2])
        }
    }

    func testChainedWrongManualRetry() {
        let queue = Queuer(name: "ConcurrentOperationTestChainedWrongManualRetry")
        let testExpectation = expectation(description: "Chained Wrong Manual Retry")
        var order: [Int] = []

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

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, [0])
        }
    }
}
