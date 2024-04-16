//
//  QueuerTests.swift
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

final class QueuerTests: XCTestCase {
    #if !os(Linux)
    func testOperationCount() {
        let queue = Queuer(name: "QueuerTestOperationCount")
        let testExpectation = expectation(description: "Operation Count")

        XCTAssertEqual(queue.operationCount, 0)

        let concurrentOperation = ConcurrentOperation { _ in
            Thread.sleep(forTimeInterval: 2)
            testExpectation.fulfill()
        }
        concurrentOperation.addToQueue(queue)
        XCTAssertEqual(queue.operationCount, 1)

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
        }
    }

    func testOperations() {
        let queue = Queuer(name: "QueuerTestOperations")
        let testExpectation = expectation(description: "Operations")

        let concurrentOperation = ConcurrentOperation { _ in
            Thread.sleep(forTimeInterval: 2)
            testExpectation.fulfill()
        }
        queue.addOperation(concurrentOperation)
        XCTAssertTrue(queue.operations.contains(concurrentOperation))

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertFalse(queue.operations.contains(concurrentOperation))
        }
    }
    #endif

    func testMaxConcurrentOperationCount() {
        let queue = Queuer(name: "QueuerTestMaxConcurrentOperationCount")

        queue.maxConcurrentOperationCount = 10

        XCTAssertEqual(queue.maxConcurrentOperationCount, 10)
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

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }

    func testAddOperation() {
        let queue = Queuer(name: "QueuerTestAddOperation")
        let testExpectation = expectation(description: "Add Operation")

        let concurrentOperation = ConcurrentOperation { _ in
            XCTAssertEqual(queue.operationCount, 1)
            Thread.sleep(forTimeInterval: 0.5)
            testExpectation.fulfill()
        }
        queue.addOperation(concurrentOperation)

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
        }
    }

    func testAddOperations() {
        let queue = Queuer(name: "QueuerTestAddOperations")
        let testExpectation = expectation(description: "Add Operations")
        var check = 0

        let concurrentOperation1 = ConcurrentOperation { _ in
            check += 1
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            check += 1
        }
        queue.addOperation(concurrentOperation1)
        XCTAssertEqual(queue.operationCount, 1)

        queue.addOperation(concurrentOperation2)
        XCTAssertEqual(queue.operationCount, 2)

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
            XCTAssertEqual(check, 2)
        }
    }

    func testAddChainedOperations() {
        let queue = Queuer(name: "QueuerTestAddChainedOperations")
        let testExpectation = expectation(description: "Add Chained Operations")
        var order: [Int] = []

        let concurrentOperation1 = ConcurrentOperation { _ in
            Thread.sleep(forTimeInterval: 2)
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, [0, 1, 2])
        }
    }

    func testAddChainedOperationsList() {
        let queue = Queuer(name: "QueuerTestAddChainedOperationsList")
        let testExpectation = expectation(description: "Add Chained Operations List")
        var order: [Int] = []

        let concurrentOperation1 = ConcurrentOperation { _ in
            Thread.sleep(forTimeInterval: 2)
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations(concurrentOperation1, concurrentOperation2) {
            order.append(2)
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, [0, 1, 2])
        }
    }

    func testAddChainedOperationsEmpty() {
        let queue = Queuer(name: "QueuerTestAddChainedOperationsEmpty")
        let testExpectation = expectation(description: "Add Chained Operations Empty")

        queue.addChainedOperations([]) {
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
        }
    }

    func testAddChainedOperationsWithoutCompletion() {
        let queue = Queuer(name: "QueuerTestAddChainedOperationsWithoutCompletion")
        let testExpectation = expectation(description: "Add Chained Operations Without Completion")
        var order: [Int] = []

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
            Thread.sleep(forTimeInterval: 0.5)
            testExpectation.fulfill()
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2])

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
            XCTAssertEqual(order, [0, 1])
        }
    }

    func testCancelAll() {
        let queue = Queuer(name: "QueuerTestCancellAll")
        let testExpectation = expectation(description: "Cancell All Operations")
        var order: [Int] = []

        let concurrentOperation1 = SynchronousOperation { _ in
            Thread.sleep(forTimeInterval: 2)
            order.append(0)
        }
        let concurrentOperation2 = SynchronousOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
        }

        queue.cancelAll()

        let deadline = DispatchTime.now() + .milliseconds(500)
        DispatchQueue.global(qos: .background).asyncAfter(deadline: deadline) {
            testExpectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertNotEqual(order.count, 3)
        }
    }

    func testPauseAndResume() {
        let queue = Queuer(name: "QueuerTestPauseAndResume")
        let testExpectation = expectation(description: "Pause and Resume")
        var order: [Int] = []

        let concurrentOperation1 = ConcurrentOperation { _ in
            Thread.sleep(forTimeInterval: 2)
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
        }

        queue.pause()

        XCTAssertLessThanOrEqual(queue.operationCount, 3)
        testExpectation.fulfill()

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertFalse(queue.isExecuting)
            XCTAssertLessThanOrEqual(queue.operationCount, 3)
            XCTAssertNotEqual(order, [0, 1, 2])

            queue.resume()
            XCTAssertTrue(queue.isExecuting)
        }
    }

    #if !os(Linux)
    func testWaitUnitlAllOperationsAreFinished() {
        let queue = Queuer(name: "QueuerTestWaitUnitlAllOperationsAreFinished")
        let testExpectation = expectation(description: "Wait Unitl All Operations Are Finished")
        var order: [Int] = []

        let concurrentOperation1 = ConcurrentOperation { _ in
            Thread.sleep(forTimeInterval: 2)
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
        }

        queue.waitUntilAllOperationsAreFinished()

        XCTAssertEqual(order, [0, 1, 2])
        XCTAssertLessThanOrEqual(queue.operationCount, 3)
        testExpectation.fulfill()

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertTrue(queue.isExecuting)
            XCTAssertLessThanOrEqual(queue.operationCount, 3)
            XCTAssertEqual(order, [0, 1, 2])

            queue.resume()
            XCTAssertTrue(queue.isExecuting)
        }
    }
    #endif
}
