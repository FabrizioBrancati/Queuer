//
//  QueuerTests.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 Fabrizio Brancati
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

import XCTest
@testable import Queuer

class QueuerTests: XCTestCase {
    static let allTests = [
        ("testOperationCount", testOperationCount),
        ("testOperations", testOperations),
        ("testMaxConcurrentOperationCount", testMaxConcurrentOperationCount),
        ("testInitWithName", testInitWithName),
        ("testAddOperationBlock", testAddOperationBlock),
        ("testAddOperation", testAddOperation),
        ("testAddChainedOperations", testAddChainedOperations),
        ("testCancelAll", testCancelAll),
        ("testPauseAndResume", testPauseAndResume)
    ]
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testOperationCount() {
        let queue = Queuer(name: "QueuerTestOperationCount")
        
        XCTAssertEqual(queue.operationCount, 0)
        
        let concurrentOperation = ConcurrentOperation()
        concurrentOperation.addToQueue(queue)
        XCTAssertEqual(queue.operationCount, 1)
        
        concurrentOperation.finish()
        XCTAssertEqual(queue.operationCount, 0)
    }
    
    func testOperations() {
        let queue = Queuer(name: "QueuerTestOperations")
        
        let concurrentOperation = ConcurrentOperation()
        queue.addOperation(concurrentOperation)
        XCTAssertTrue(queue.operations.contains(concurrentOperation))
        
        concurrentOperation.finish()
        XCTAssertFalse(queue.operations.contains(concurrentOperation))
    }
    
    func testMaxConcurrentOperationCount() {
        let queue = Queuer(name: "QueuerTestMaxConcurrentOperationCount")
        
        queue.maxConcurrentOperationCount = 10
        
        XCTAssertEqual(queue.maxConcurrentOperationCount, 10)
    }
    
    func testInitWithName() {
        let queueName = "TestInitWithName"
        let queue = Queuer(name: queueName)
        
        XCTAssertEqual(queue.queue.name, queueName)
    }
    
    func testAddOperationBlock() {
        let queue = Queuer(name: "QueuerTestAddOperationBlock")
        
        let testExpectation = expectation(description: "Add Operation Block")
        
        queue.addOperation {
            XCTAssertEqual(queue.operationCount, 1)
            testExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
        })
    }
    
    func testAddOperation() {
        let queue = Queuer(name: "QueuerTestAddOperation")
        
        let testExpectation = expectation(description: "Add Operation")
        
        let concurrentOperation = ConcurrentOperation {
            XCTAssertEqual(queue.operationCount, 1)
            testExpectation.fulfill()
        }
        queue.addOperation(concurrentOperation)
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
        })
    }
    
    func testAddChainedOperations() {
        let queue = Queuer(name: "QueuerTestAddChainedOperations")
        
        let testExpectation = expectation(description: "Add Chained Operations")
        var order: [Int] = []
        
        let concurrentOperation1 = ConcurrentOperation{
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation {
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
            testExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
            XCTAssertEqual(order, [0, 1, 2])
        })
    }
    
    func testCancelAll() {
        let queue = Queuer(name: "QueuerTestCancellAll")
        
        let testExpectation = expectation(description: "Cancell All Operations")
        var order: [Int] = []
        
        let concurrentOperation1 = ConcurrentOperation {
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation {
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
        }
        
        queue.cancelAll()
        testExpectation.fulfill()
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(queue.operationCount, 0)
            XCTAssertNotEqual(order.count, 3)
        })
    }
    
    func testPauseAndResume() {
        let queue = Queuer(name: "QueuerTestPauseAndResume")
        
        let testExpectation = expectation(description: "Pause and Resume Queuer")
        var order: [Int] = []
        
        let concurrentOperation1 = ConcurrentOperation {
            sleep(2)
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation {
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
        }
        
        queue.pause()
        testExpectation.fulfill()
        
        XCTAssertLessThanOrEqual(queue.operationCount, 3)
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(queue.isExecuting)
            XCTAssertLessThanOrEqual(queue.operationCount, 3)
            XCTAssertNotEqual(order, [0, 1, 2])
            
            queue.resume()
            XCTAssertTrue(queue.isExecuting)
        })
    }
}
