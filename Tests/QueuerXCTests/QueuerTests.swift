//
//  QueuerTests.swift
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

final class QueuerTests: XCTestCase {
    func testOperationCount() {
        let queue = Queuer(name: "QueuerTestOperationCount")
        let testExpectation = expectation(description: "Operation Count")
        let operationStarted = DispatchSemaphore(value: 0)
        let releaseOperation = DispatchSemaphore(value: 0)

        XCTAssertEqual(queue.operationCount, 0)

        let concurrentOperation = ConcurrentOperation { _ in
            operationStarted.signal()
            /// Keep the operation alive until the count has been verified.
            _ = releaseOperation.wait(timeout: .now() + .seconds(8))
        }
        concurrentOperation.addToQueue(queue)

        XCTAssertEqual(operationStarted.wait(timeout: .now() + .seconds(8)), .success)
        XCTAssertEqual(queue.operationCount, 1)
        releaseOperation.signal()

        /// The operation needs some time to leave the queue after its block returns,
        /// so poll the count instead of asserting right away.
        fulfill(testExpectation, when: { queue.operationCount == 0 })

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
        }
    }

    func testOperations() {
        let queue = Queuer(name: "QueuerTestOperations")
        let testExpectation = expectation(description: "Operations")
        let operationStarted = DispatchSemaphore(value: 0)
        let releaseOperation = DispatchSemaphore(value: 0)

        let concurrentOperation = ConcurrentOperation { _ in
            operationStarted.signal()
            _ = releaseOperation.wait(timeout: .now() + .seconds(8))
        }
        queue.addOperation(concurrentOperation)

        XCTAssertEqual(operationStarted.wait(timeout: .now() + .seconds(8)), .success)
        XCTAssertTrue(queue.operations.contains(concurrentOperation))
        releaseOperation.signal()

        fulfill(testExpectation, when: { !queue.operations.contains(concurrentOperation) })

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertFalse(queue.operations.contains(concurrentOperation))
        }
    }

    func testMaxConcurrentOperationCount() {
        let queue = Queuer(name: "QueuerTestMaxConcurrentOperationCount")

        queue.maxConcurrentOperationCount = 10

        XCTAssertEqual(queue.maxConcurrentOperationCount, 10)
    }

    func testMaxConcurrentOperationCountSetToOne() {
        let testExpectation = expectation(description: "Max Concurrent Operation Count Set To One")
        let testString = Protected("")

        let concurrentOperation1 = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested1" }
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested2" }

            /// On a serial queue `concurrentOperation2` is guaranteed to run last.
            testExpectation.fulfill()
        }
        Queuer.shared.maxConcurrentOperationCount = 1
        Queuer.shared.addOperation(concurrentOperation1)
        Queuer.shared.addOperation(concurrentOperation2)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(testString.value, "Tested2")
        }
    }

    func testQualityOfService() {
        let queue = Queuer(name: "QueuerTestMaxConcurrentOperationCount")

        queue.qualityOfService = .background

        XCTAssertEqual(queue.qualityOfService, .background)
    }

    func testInitWithNameMaxConcurrentOperationCount() {
        let queueName = "TestInitWithNameMaxConcurrentOperationCount"
        let queue = Queuer(name: queueName, maxConcurrentOperationCount: 10)

        XCTAssertEqual(queue.queue.name, queueName)
        XCTAssertEqual(queue.queue.maxConcurrentOperationCount, 10)
    }

    func testInitWithNameMaxConcurrentOperationCountQualityOfService() {
        let queueName = "TestInitWithNameMaxConcurrentOperationCountQualityOfService"
        let queue = Queuer(name: queueName, maxConcurrentOperationCount: 10, qualityOfService: .background)

        XCTAssertEqual(queue.queue.name, queueName)
        XCTAssertEqual(queue.queue.maxConcurrentOperationCount, 10)
        XCTAssertEqual(queue.queue.qualityOfService, .background)
    }

    func testAddOperationBlock() {
        let queue = Queuer(name: "QueuerTestAddOperationBlock")
        let testExpectation = expectation(description: "Add Operation Block")

        queue.addOperation {
            XCTAssertEqual(queue.operationCount, 1)
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testAddOperation() {
        let queue = Queuer(name: "QueuerTestAddOperation")
        let testExpectation = expectation(description: "Add Operation")

        let concurrentOperation = ConcurrentOperation { _ in
            XCTAssertEqual(queue.operationCount, 1)
        }
        queue.addOperation(concurrentOperation)

        fulfill(testExpectation, when: { queue.operationCount == 0 })

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
        }
    }

    func testAddOperations() {
        let queue = Queuer(name: "QueuerTestAddOperations")
        let testExpectation = expectation(description: "Add Operations")
        let check = Protected(0)
        let releaseOperations = DispatchSemaphore(value: 0)

        let concurrentOperation1 = ConcurrentOperation { _ in
            _ = releaseOperations.wait(timeout: .now() + .seconds(8))
            check.mutate { $0 += 1 }
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            _ = releaseOperations.wait(timeout: .now() + .seconds(8))
            check.mutate { $0 += 1 }
        }
        queue.addOperation(concurrentOperation1)
        XCTAssertEqual(queue.operationCount, 1)

        queue.addOperation(concurrentOperation2)
        XCTAssertEqual(queue.operationCount, 2)

        releaseOperations.signal()
        releaseOperations.signal()

        fulfill(testExpectation, when: { queue.operationCount == 0 && check.value == 2 })

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
            XCTAssertEqual(check.value, 2)
        }
    }

    func testAddChainedOperations() {
        let queue = Queuer(name: "QueuerTestAddChainedOperations")
        let testExpectation = expectation(description: "Add Chained Operations")
        let order = Protected<[Int]>([])

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0, 1, 2])
        }
    }

    func testAddChainedOperationsList() {
        let queue = Queuer(name: "QueuerTestAddChainedOperationsList")
        let testExpectation = expectation(description: "Add Chained Operations List")
        let order = Protected<[Int]>([])

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations(concurrentOperation1, concurrentOperation2) {
            order.append(2)
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0, 1, 2])
        }
    }

    func testAddChainedOperationsEmpty() {
        let queue = Queuer(name: "QueuerTestAddChainedOperationsEmpty")
        let testExpectation = expectation(description: "Add Chained Operations Empty")
        let completed = Protected(false)

        queue.addChainedOperations([]) {
            completed.mutate { $0 = true }
        }

        /// The completion handler runs as an operation itself,
        /// so wait for the queue to be empty before asserting.
        fulfill(testExpectation, when: { completed.value && queue.operationCount == 0 })

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
        }
    }

    func testAddChainedOperationsWithoutCompletion() {
        let queue = Queuer(name: "QueuerTestAddChainedOperationsWithoutCompletion")
        let testExpectation = expectation(description: "Add Chained Operations Without Completion")
        let order = Protected<[Int]>([])

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2])

        fulfill(testExpectation, when: { queue.operationCount == 0 && order.count == 2 })

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
            XCTAssertEqual(order.value, [0, 1])
        }
    }

    func testCancel() {
        let queue = Queuer(name: "QueuerTestCancel")
        let testExpectation = expectation(description: "Cancel All Operations")
        let order = Protected<[Int]>([])

        /// Pause the queue so that no operation can start before `cancel()` is called.
        queue.pause()

        /// The operations are intentionally not chained: on Linux, canceling
        /// dependency-linked operations can crash inside corelibs-foundation's
        /// KVO handling when dependents finish before their prerequisites.
        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addOperation(concurrentOperation1)
        queue.addOperation(concurrentOperation2)

        queue.cancel()
        queue.resume()

        fulfill(testExpectation, when: { queue.operationCount == 0 })

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [])
        }
    }

    func testPauseAndResume() {
        let queue = Queuer(name: "QueuerTestPauseAndResume")
        let testExpectation = expectation(description: "Pause and Resume")
        let order = Protected<[Int]>([])

        /// Pause the queue before adding operations so that none of them can start.
        queue.pause()
        XCTAssertFalse(queue.isExecuting)

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
            testExpectation.fulfill()
        }

        XCTAssertEqual(queue.operationCount, 3)
        XCTAssertEqual(order.value, [])

        queue.resume()
        XCTAssertTrue(queue.isExecuting)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0, 1, 2])
        }
    }

    func testWaitUnitlAllOperationsAreFinished() {
        let queue = Queuer(name: "QueuerTestWaitUnitlAllOperationsAreFinished")
        let order = Protected<[Int]>([])

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
        }

        queue.waitUntilAllOperationsAreFinished()

        XCTAssertEqual(order.value, [0, 1, 2])
        XCTAssertEqual(queue.operationCount, 0)
        XCTAssertTrue(queue.isExecuting)
    }

    func testCompletionWaitsForAllOperations() {
        let queue = Queuer(name: "QueuerTestCompletionWaitsForAllOperations")
        let testExpectation = expectation(description: "Completion Waits For All Operations")
        let order = Protected<[String]>([])
        let releaseSlowOperation = DispatchSemaphore(value: 0)

        /// The slow operation is added first, the fast one last:
        /// the completion must wait for both, not just for the last added one.
        let slowOperation = ConcurrentOperation { _ in
            _ = releaseSlowOperation.wait(timeout: .now() + .seconds(8))
            order.append("slow")
        }
        let fastOperation = ConcurrentOperation { _ in
            order.append("fast")
        }
        queue.addOperation(slowOperation)
        queue.addOperation(fastOperation)

        queue.addCompletionHandler {
            order.append("done")
            testExpectation.fulfill()
        }

        releaseSlowOperation.signal()

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value.last, "done")
            XCTAssertEqual(Set(order.value), ["slow", "fast", "done"])
        }
    }
}
